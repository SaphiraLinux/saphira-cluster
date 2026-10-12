# Resource policy: what "spare" means

Slurm schedules what we tell it is available. It does not watch a web
server and decide cores happen to be idle. v1 is therefore deliberately
conservative: statically reserve service capacity, let Slurm own only
the remainder.

## Definitions

- **Total**: what the hardware has (`saphira-cluster resources`).
- **Reserved**: CPUs/RAM kept for the OS, nginx, MariaDB, KVM guests
  and other services. Expressed with `--reserve-*` at enrol time.
- **Advertised**: total minus reserved. This and only this enters
  `slurm.conf` (`CPUs`, `RealMemory`) and GRES.

The machine remains a service host first; the cluster gets the rest.

## Enforcement (all required, not optional)

- `select/cons_tres` task/plugin selection.
- `task/cgroup` with cgroup v2 (`--enable-cgroupv2` is a hard recipe
  requirement, explicit so a missing header fails closed).
- `ConstrainCores=yes`, `ConstrainRAMSpace=yes` semantics via the
  generated `cgroup.conf`.
- Core/memory specialisation: `CoreSpecCount`/`CPUSpecList` and
  `MemSpecLimit` reserve service cores/RAM *inside* Slurm's view so
  even the advertised node cannot schedule onto them.

Acceptance is not "a job runs". Acceptance is "a job cannot consume
CPUs/RAM reserved for services" (see `docs/acceptance.md`).

## VM-versus-host ownership invariant

A physical resource is advertised at most once, cluster-wide.

- If a host runs `slurmd`, its VMs must not advertise the same physical
  CPUs/RAM.
- A VM may advertise only its hard allocation.
- A passthrough GPU belongs to either host or VM, never both.
- `saphira-cluster doctor` grows a duplicate-resource check once
  enrolment state exists.

## Storage position (v1)

Slurm schedules compute; it does not move files. Jobs require shared
storage or explicit staging &mdash; stated in job documentation, never
assumed. ZFS is excellent local storage; NFS-on-ZFS is the obvious
later shared option. Storage is not bundled into `saphira-cluster`.

## Identity position (v1)

A submitting UID/GID must mean the same user on every node. v1 uses
local accounts with matching IDs; `doctor` verifies the `slurm`
service identity today and extends to submitting users with enrolment.
