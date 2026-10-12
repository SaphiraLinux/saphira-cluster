# Saphira Cluster

Reserved-capacity compute clustering for Saphira: upstream Slurm packaged
site-neutrally, plus a small native control utility (`saphira-cluster`)
that turns Saphira hosts into Slurm clusters without hiding Slurm.

## Architecture

```text
LVS / ldirectord     distributes service traffic
Slurm                distributes scheduled compute
saphira-cluster      configures and protects the Saphira hosts
```

v1 is **reserved-capacity clustering**, not idle harvesting. Slurm
schedules only what we explicitly advertise; service capacity for
nginx, MariaDB, KVM and the OS is reserved first and Slurm owns only
the remainder. Dynamic grow-when-idle / shrink-when-busy behaviour is
a separate future design, not something static Slurm configuration
pretends to do.

## Layout and boundary

Two products. Recipes live in the Saphira Linux recipe tree
(`/recipes`) — never in this repo. This repo holds the
`saphira-cluster` product source and the project documentation.

| Path                               | Contents                                 | May contain site data? |
|------------------------------------|------------------------------------------|------------------------|
| `/recipes/slurm/`                  | Slurm core (clients, ctld, slurmd, sackd)| Never                  |
| `/recipes/slurm-accounting/`       | Optional slurmdbd + mysql plugin         | Never                  |
| `/recipes/saphira-cluster/`        | Our C utility as an APK                  | Never                  |
| `saphira-cluster/` (this repo)     | C source, man page, tests                | Never                  |
| `docs/` (this repo)                | Policy, matrices, acceptance plan        | Never                  |
| `docs/examples/` (this repo)       | Walkthroughs naming real machines        | Yes, docs only         |
| Runtime config                     | Generated on the target                  | Never committed        |

Someone downloading Saphira's Slurm package anywhere receives exactly
the same package installed on our own controller; only
`saphira-cluster` turns it into their cluster. Installed templates use
generic placeholders (`controller`, `node01`, `node02`). The packages
never enable daemons and never create a cluster on install. A normal
cluster is `apk add slurm saphira-cluster`; accounting adds
`apk add slurm-accounting`.

## Status

- Slurm 26.05.4 recipes: written, source vendored and checksum-verified,
  **not yet built** (builder trial pending). See `docs/build-matrix.md`.
- `saphira-cluster` C scaffold: CLI parser, `--help`, `resources` and
  `doctor` are real; mutating commands (`init`, `node`, `apply`, ...)
  parse but report unimplemented. Host-executed scaffold tests pass;
  package build comes later via a recipe.
- First deployment target: configless CPU/RAM cluster; `auth/slurm`
  and MUNGE both to be proven before a default is declared; GPU whole
  device after that; MPS/sharding last.

## Documentation

- `docs/boundary.md` — packaging purity rules.
- `docs/resource-policy.md` — spare-resource definition, isolation,
  VM-versus-host ownership invariant.
- `docs/build-matrix.md` — Slurm plugin matrix and follow-up packages.
- `docs/acceptance.md` — multi-node acceptance gates.
- `docs/examples/` — real-machine walkthroughs (documentation only).
