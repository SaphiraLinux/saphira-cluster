/* SPDX-License-Identifier: BUSL-1.1 */
/* Single source of --help truth. The man page mirrors this. */

#include <stdio.h>

#include "cluster.h"

void
sc_usage(void)
{
	printf("usage: saphira-cluster <command> [options]\n");
	printf("\n");
	printf("Configure and protect Saphira hosts for Slurm.\n");
	printf("Slurm schedules; saphira-cluster does not.\n");
	printf("\n");
	printf("commands:\n");
	printf("  init <name> --controller <host>\n");
	printf("      start a new cluster definition (unimplemented)\n");
	printf("  node add <host> [--reserve-cpus N] [--reserve-memory SIZE]\n");
	printf("                 [--gpu auto] [--gpu-share SPEC] [--no-exec]\n");
	printf("      enrol a node (unimplemented)\n");
	printf("  node remove <host>    drop a node (unimplemented)\n");
	printf("  apply                 write generated config (unimplemented)\n");
	printf("  validate              check generated config (unimplemented)\n");
	printf("  status                show cluster state (unimplemented)\n");
	printf("  resources             show local CPU/RAM/GPU capability\n");
	printf("  doctor                run read-only node health checks\n");
	printf("  help                  show this text\n");
	printf("  version               show version\n");
	printf("\n");
	printf("options:\n");
	printf("  --help      show this text (anywhere)\n");
	printf("  --version   show version (anywhere)\n");
	printf("\n");
	printf("exit codes: 0 ok, 1 usage error, 2 check failed, 3 unimplemented\n");
}

int
cmd_help(int argc, char **argv)
{
	(void)argc;
	(void)argv;
	sc_usage();
	return SC_OK;
}

int
cmd_stub(int argc, char **argv)
{
	fprintf(stderr, "saphira-cluster %s: not yet implemented\n", argv[0]);
	fprintf(stderr, "scaffold scope is --help, resources and doctor only\n");
	(void)argc;
	return SC_UNIMPL;
}
