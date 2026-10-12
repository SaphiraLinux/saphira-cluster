# Multi-node acceptance gates

Synthetic names throughout; real-machine walkthroughs live in
`docs/examples/` only.

## Gate 1: configless CPU/RAM cluster (required first)

1. Controller installed on `controller`; `slurm.conf` generated there
   with `SlurmctldParameters=enable_configless`, same Slurm major.minor
   line everywhere (mixed releases unsupported in v1).
2. Compute nodes `node01`, `node02` fetch config from the controller;
   no hand-edited configs on nodes.
3. `sinfo` shows both nodes; a CPU job lands on each (`srun -N1 -c4`).
4. Memory limit proven: a job exceeding its allocation is killed, and
   `sacct` records it.
5. Reservation proven: load the reserved cores with service traffic and
   show Slurm jobs cannot consume them (`CoreSpecCount`/`MemSpecLimit`
   effective, cgroup confinement observed).
6. Node reboot and rejoin proven; controller reboot with state recovery
   proven (`StateSaveLocation` survives).
7. UID/GID consistency, hostname resolution, IPv4/IPv6 reachability and
   clock sync verified by `saphira-cluster doctor` on every node.

## Gate 2: auth decision

Run Gate 1 twice: once with `auth/slurm`, once with MUNGE (after the
MUNGE package exists). Declare the Saphira default only on evidence.

## Gate 3: whole-GPU allocation (separate gate, after Gate 1 is green)

Whole-device `--gres=gpu:1` jobs on a GPU node; service-reserved GPUs
never scheduled; host/VM ownership invariant holds.

## Gate 4: MPS/sharding (last)

Fractional `mps`/`shard` GRES only after Gates 1&ndash;3 are green.

## Explicitly not gates for v1

Dynamic idle harvesting, shared-filesystem transparency, controller HA,
`slurmdbd` accounting history, REST API. Each is real future work with
its own design, not a failed gate.
