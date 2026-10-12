/* SPDX-License-Identifier: MIT */
/* Show local hardware capability. Read-only. */

#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <sys/utsname.h>
#include <unistd.h>

#include "cluster.h"

int sc_cgroup_v2(void);

static long
meminfo(const char *key)
{
	FILE *fp;
	char line[256];
	char name[64];
	long value;
	long found;

	found = -1;
	fp = fopen("/proc/meminfo", "r");
	if (fp == NULL)
		return -1;
	while (fgets(line, sizeof line, fp) != NULL) {
		if (sscanf(line, "%63[^:]: %ld", name, &value) == 2 &&
		    strcmp(name, key) == 0) {
			found = value;
			break;
		}
	}
	fclose(fp);
	return found;
}

static int
cpu_count(char *model, unsigned long n)
{
	FILE *fp;
	char line[512];
	int count;

	count = 0;
	model[0] = '\0';
	fp = fopen("/proc/cpuinfo", "r");
	if (fp == NULL)
		return -1;
	while (fgets(line, sizeof line, fp) != NULL) {
		if (strncmp(line, "processor", 9) == 0)
			count++;
		else if (model[0] == '\0' &&
		    strncmp(line, "model name", 10) == 0) {
			char *p = strchr(line, ':');
			if (p != NULL) {
				p++;
				while (*p == ' ' || *p == '\t')
					p++;
				strncpy(model, p, n - 1);
				model[n - 1] = '\0';
				n = strlen(model);
				while (n > 0 &&
				    (model[n - 1] == '\n' ||
				     model[n - 1] == ' ' ||
				     model[n - 1] == '\t'))
					model[--n] = '\0';
			}
		}
	}
	fclose(fp);
	return count;
}

/* List PCI display/3D controllers: class 0x03xxxx. */
static void
list_gpus(void)
{
	DIR *dir;
	struct dirent *ent;
	char path[512];
	char classbuf[16];
	char vendbuf[16];
	char devbuf[16];
	FILE *fp;
	int found;

	found = 0;
	dir = opendir("/sys/bus/pci/devices");
	if (dir == NULL) {
		printf("  gpu: pci inventory unavailable\n");
		return;
	}
	while ((ent = readdir(dir)) != NULL) {
		unsigned cls;

		if (ent->d_name[0] == '.')
			continue;
		sprintf(path, "/sys/bus/pci/devices/%s/class",
		    ent->d_name);
		fp = fopen(path, "r");
		if (fp == NULL)
			continue;
		if (fgets(classbuf, sizeof classbuf, fp) == NULL) {
			fclose(fp);
			continue;
		}
		fclose(fp);
		if (sscanf(classbuf, "%x", &cls) != 1)
			continue;
		if ((cls & 0xffff00U) != 0x030000U &&
		    (cls & 0xffff00U) != 0x038000U)
			continue;
		sprintf(path, "/sys/bus/pci/devices/%s/vendor",
		    ent->d_name);
		fp = fopen(path, "r");
		vendbuf[0] = '\0';
		if (fp != NULL) {
			if (fgets(vendbuf, sizeof vendbuf, fp) != NULL)
				vendbuf[strcspn(vendbuf, "\r\n")] = '\0';
			fclose(fp);
		}
		sprintf(path, "/sys/bus/pci/devices/%s/device",
		    ent->d_name);
		fp = fopen(path, "r");
		devbuf[0] = '\0';
		if (fp != NULL) {
			if (fgets(devbuf, sizeof devbuf, fp) != NULL)
				devbuf[strcspn(devbuf, "\r\n")] = '\0';
			fclose(fp);
		}
		printf("  gpu %s: class %06x vendor %s device %s",
		    ent->d_name, cls & 0xffffffU,
		    vendbuf[0] ? vendbuf : "?\n",
		    devbuf[0] ? devbuf : "?\n");
		found++;
	}
	closedir(dir);
	if (!found)
		printf("  gpu: none detected\n");
	else
		printf("  cuda/mps: probe via the vendor driver, "
		    "not linked into this tool\n");
}

int
cmd_resources(int argc, char **argv)
{
	char host[256];
	char model[128];
	struct utsname un;
	int cpus;
	long total, avail;

	(void)argc;
	(void)argv;
	if (gethostname(host, sizeof host) != 0)
		strcpy(host, "unknown");
	cpus = cpu_count(model, sizeof model);
	total = meminfo("MemTotal");
	avail = meminfo("MemAvailable");
	printf("%s\n", host);
	if (cpus >= 0) {
		if (model[0])
			printf("  cpu: %d threads (%s)\n", cpus, model);
		else
			printf("  cpu: %d threads\n", cpus);
	} else {
		printf("  cpu: unknown\n");
	}
	if (total >= 0)
		printf("  memory: %ld kB total", total);
	else
		printf("  memory: unknown");
	if (avail >= 0)
		printf(", %ld kB available\n", avail);
	else
		printf("\n");
	if (uname(&un) == 0)
		printf("  kernel: %s %s\n", un.sysname, un.release);
	printf("  cgroup: %s\n", sc_cgroup_v2() ? "v2" : "not v2");
	list_gpus();
	printf("  note: advertised capacity is total minus the Saphira\n");
	printf("  service reservation; see docs/resource-policy.md\n");
	return SC_OK;
}
