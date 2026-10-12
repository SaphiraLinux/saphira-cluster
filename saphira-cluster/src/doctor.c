/* SPDX-License-Identifier: BUSL-1.1 */
/* Read-only node health checks. Exit SC_FAIL on any failure. */

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <pwd.h>
#include <sys/socket.h>
#include <sys/timex.h>
#include <unistd.h>

#include "cluster.h"

int sc_cgroup_v2(void);
int sc_capture(const char *cmd, char *buf, unsigned long n);
int sc_version(const char *s, unsigned *major, unsigned *minor);

static int failures = 0;

static void
report(const char *name, int ok, const char *detail)
{
	printf("[%s] %s%s%s\n", ok ? "ok" : "FAIL", name,
	    detail ? ": " : "", detail ? detail : "");
	if (!ok)
		failures++;
}

static void
check_hostname(void)
{
	char host[256];
	struct addrinfo hints;
	struct addrinfo *res;

	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	if (gethostname(host, sizeof host) != 0) {
		report("hostname", 0, "gethostname failed");
		return;
	}
	if (getaddrinfo(host, NULL, &hints, &res) != 0) {
		report("hostname-resolves", 0, host);
		return;
	}
	freeaddrinfo(res);
	report("hostname-resolves", 1, host);
}

static void
check_ipv6(void)
{
	FILE *fp;

	fp = fopen("/proc/net/if_inet6", "r");
	if (fp != NULL) {
		fclose(fp);
		report("ipv6", 1, "present");
		return;
	}
	report("ipv6", 0, "no /proc/net/if_inet6");
}

static void
check_clock(void)
{
	struct timex tx;

	memset(&tx, 0, sizeof tx);
	if (adjtimex(&tx) < 0) {
		report("clock", 1, "time readable, sync state unknown");
		return;
	}
	if (tx.status & STA_UNSYNC)
		report("clock", 0, "unsynchronised");
	else
		report("clock", 1, "synchronised");
}

static void
check_slurm_user(void)
{
	struct passwd *pw;
	char detail[128];

	pw = getpwnam("slurm");
	if (pw == NULL) {
		report("slurm-user", 0, "no slurm account (install slurm)");
		return;
	}
	sprintf(detail, "uid %lu gid %lu", (unsigned long)pw->pw_uid,
	    (unsigned long)pw->pw_gid);
	report("slurm-user", 1, detail);
}

/* Slurm default ports: 6817 ctld, 6818 slurmd, 6819 dbd, 6820 restd.
 * Informational: a compute node need not listen on all of them. */
static void
check_ports(void)
{
	static const int ports[] = { 6817, 6818, 6819, 6820 };
	FILE *fp;
	char line[512];
	char wanted[4];
	int i;

	for (i = 0; i < 4; i++)
		wanted[i] = 0;
	fp = fopen("/proc/net/tcp", "r");
	if (fp == NULL)
		fp = NULL;
	if (fp != NULL) {
		while (fgets(line, sizeof line, fp) != NULL) {
			unsigned addr, port;
			char state[16];
			(void)addr;
			if (sscanf(line, "%*d: %x:%x %*s %15s",
			    &addr, &port, state) != 3)
				continue;
			if (strcmp(state, "0A") != 0)
				continue;
			for (i = 0; i < 4; i++)
				if ((int)port == ports[i])
					wanted[i] = 1;
		}
		fclose(fp);
	}
	fp = fopen("/proc/net/tcp6", "r");
	if (fp != NULL) {
		while (fgets(line, sizeof line, fp) != NULL) {
			unsigned port;
			char *colon;
			char state[16];

			colon = strrchr(line, ':');
			if (colon == NULL)
				continue;
			if (sscanf(colon + 1, "%x %*s %15s",
			    &port, state) != 2)
				continue;
			if (strcmp(state, "0A") != 0)
				continue;
			for (i = 0; i < 4; i++)
				if ((int)port == ports[i])
					wanted[i] = 1;
		}
		fclose(fp);
	}
	for (i = 0; i < 4; i++) {
		char detail[32];

		sprintf(detail, "port %d %slistening", ports[i],
		    wanted[i] ? "" : "not ");
		report("slurm-port", 1, detail);
	}
}

/* Compare tool and daemon Slurm lines when both are installed. */
static void
check_slurm_versions(void)
{
	char tool[128];
	char daemon[128];
	unsigned tmaj, tmin, dmaj, dmin;
	int havetool, haved;
	char detail[256];

	havetool = sc_capture("/usr/bin/sinfo -V", tool, sizeof tool);
	haved = sc_capture("/usr/sbin/slurmd -V", daemon, sizeof daemon);
	if (havetool != 0 && haved != 0) {
		report("slurm-version", 1, "slurm not installed");
		return;
	}
	if (havetool != 0 || haved != 0) {
		sprintf(detail, "partial install (tool %s, daemon %s)",
		    havetool == 0 ? "present" : "absent",
		    haved == 0 ? "present" : "absent");
		report("slurm-version", 1, detail);
		return;
	}
	if (sc_version(tool, &tmaj, &tmin) != 0 ||
	    sc_version(daemon, &dmaj, &dmin) != 0) {
		report("slurm-version", 0, "unparsable version output");
		return;
	}
	if (tmaj != dmaj || tmin != dmin) {
		sprintf(detail, "mixed lines: tool %u.%u, daemon %u.%u",
		    tmaj, tmin, dmaj, dmin);
		report("slurm-version", 0, detail);
		return;
	}
	sprintf(detail, "single line %u.%u", tmaj, tmin);
	report("slurm-version", 1, detail);
}

static void
check_slurmd_capability(void)
{
	char line[512];
	FILE *fp;
	int shown;

	if (access("/usr/sbin/slurmd", X_OK) != 0) {
		report("slurmd-capability", 1, "slurmd not installed");
		return;
	}
	fp = popen("/usr/sbin/slurmd -C 2>&1", "r");
	if (fp == NULL) {
		report("slurmd-capability", 0, "slurmd -C failed");
		return;
	}
	shown = 0;
	while (shown < 4 && fgets(line, sizeof line, fp) != NULL) {
		printf("    slurmd -C: %s", line);
		shown++;
	}
	pclose(fp);
	report("slurmd-capability", 1, "see slurmd -C above");
}

int
cmd_doctor(int argc, char **argv)
{
	(void)argc;
	(void)argv;
	printf("saphira-cluster doctor (read-only; changes nothing)\n");
	check_hostname();
	check_ipv6();
	check_clock();
	report("cgroup-v2", sc_cgroup_v2(),
	    sc_cgroup_v2() ? "enforcing hierarchy available" :
	    "required for job confinement");
	check_slurm_user();
	check_slurm_versions();
	check_ports();
	check_slurmd_capability();
	if (access("/etc/slurm/slurm.conf", R_OK) == 0)
		report("slurm-conf", 1, "/etc/slurm/slurm.conf present");
	else
		report("slurm-conf", 1,
		    "absent (fine for configless nodes)");
	if (failures) {
		printf("doctor: %d failing check(s)\n", failures);
		return SC_FAIL;
	}
	printf("doctor: all checks passed\n");
	return SC_OK;
}
