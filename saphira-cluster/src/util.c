/* SPDX-License-Identifier: MIT */
/* Shared read-only helpers. */

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <string.h>
#include <sys/vfs.h>

#include "cluster.h"

/* Linux cgroup2 superblock magic; musl headers need not name it. */
#define SC_CGROUP2_MAGIC ((unsigned long)0x63677270UL)

int
sc_cgroup_v2(void)
{
	struct statfs st;

	if (statfs("/sys/fs/cgroup", &st) != 0)
		return 0;
	return st.f_type == (long)SC_CGROUP2_MAGIC;
}

/* Run cmd, capture first line of stdout. Returns 0 on success. */
int
sc_capture(const char *cmd, char *buf, unsigned long n)
{
	FILE *fp;
	size_t len;

	if (n == 0)
		return 1;
	fp = popen(cmd, "r");
	if (fp == NULL)
		return 1;
	if (fgets(buf, (int)n, fp) == NULL) {
		pclose(fp);
		return 1;
	}
	pclose(fp);
	len = strlen(buf);
	while (len > 0 &&
	    (buf[len - 1] == '\n' || buf[len - 1] == '\r'))
		buf[--len] = '\0';
	return 0;
}

/* Parse leading "X.Y" from s. Returns 0 on success. */
int
sc_version(const char *s, unsigned *major, unsigned *minor)
{
	while (*s == ' ' || *s == '\t')
		s++;
	if (sscanf(s, "%u.%u", major, minor) != 2)
		return 1;
	return 0;
}
