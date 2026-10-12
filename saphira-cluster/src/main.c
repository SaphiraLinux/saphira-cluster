/* SPDX-License-Identifier: MIT */
/* Command dispatch. K&R-compatible C89. */

#include <stdio.h>
#include <string.h>

#include "cluster.h"

static int
has_flag(int argc, char **argv, const char *flag)
{
	int i;

	for (i = 0; i < argc; i++)
		if (strcmp(argv[i], flag) == 0)
			return 1;
	return 0;
}

int
main(int argc, char **argv)
{
	if (argc < 2 || has_flag(argc, argv, "--help") ||
	    strcmp(argv[1], "help") == 0) {
		sc_usage();
		return SC_OK;
	}
	if (has_flag(argc, argv, "--version") ||
	    strcmp(argv[1], "version") == 0) {
		printf("saphira-cluster %s\n", SC_VERSION);
		return SC_OK;
	}
	if (strcmp(argv[1], "resources") == 0)
		return cmd_resources(argc - 2, argv + 2);
	if (strcmp(argv[1], "doctor") == 0)
		return cmd_doctor(argc - 2, argv + 2);
	if (strcmp(argv[1], "init") == 0 ||
	    strcmp(argv[1], "node") == 0 ||
	    strcmp(argv[1], "apply") == 0 ||
	    strcmp(argv[1], "validate") == 0 ||
	    strcmp(argv[1], "status") == 0)
		return cmd_stub(argc - 1, argv + 1);
	fprintf(stderr, "saphira-cluster: unknown command '%s'\n", argv[1]);
	fprintf(stderr, "try 'saphira-cluster --help'\n");
	return SC_USAGE;
}
