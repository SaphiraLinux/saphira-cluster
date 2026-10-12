/* SPDX-License-Identifier: BUSL-1.1 */
/* saphira-cluster: native control/configuration utility for Slurm
 * on Saphira. Discovers capability, applies reservation policy,
 * generates and validates Slurm configuration, manages enrolment,
 * and reports cluster state. It is not a scheduler. */

#ifndef CLUSTER_H
#define CLUSTER_H

#define SC_VERSION "0.1.0"

/* Exit codes, stable and documented in saphira-cluster(8). */
#define SC_OK 0		/* success */
#define SC_USAGE 1	/* bad invocation; usage was printed */
#define SC_FAIL 2	/* check failed / actionable problem found */
#define SC_UNIMPL 3	/* parsed, but not implemented in this scaffold */

int cmd_help(int argc, char **argv);
int cmd_resources(int argc, char **argv);
int cmd_doctor(int argc, char **argv);
int cmd_stub(int argc, char **argv);	/* mutating commands, later work */

void sc_usage(void);

#endif
