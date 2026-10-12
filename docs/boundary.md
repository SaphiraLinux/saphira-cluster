# Packaging purity boundary

Slurm packaging is completely site-neutral.

- No hostnames, addresses, IPs, UUIDs, GPU IDs, ZFS datasets or local
  topology in any `recipe.sh`, patch, installed default, service unit,
  accounts fragment or package test. This is verified by leak grep
  before every commit (see below).
- Recipes package upstream capability; they never describe a deployment.
- Installed configuration is upstream `.example` files only. Live
  `slurm.conf`, `gres.conf`, `cgroup.conf`, `slurmdbd.conf`, bootstrap
  state, discovered hardware data, credentials and cluster membership
  are generated on the target by `saphira-cluster` and must never enter
  this source tree.
- Packages never enable daemons and never create a cluster on install.
- Automated recipe tests use synthetic node names so they reproduce
  outside our infrastructure.
- `saphira-cluster` owns deployment policy and generated configuration;
  the Slurm recipes know nothing about any particular cluster.

## Directory contract

Recipes belong to the Saphira Linux recipe tree (`/recipes`) and never
to this repo. This repo holds the `saphira-cluster` product source and
project documentation.

```text
/recipes/slurm/              Slurm core product (clients, ctld, slurmd, sackd)
/recipes/slurm/files/        only required portable integration
/recipes/slurm-accounting/   optional companion (slurmdbd + mysql plugin)
/recipes/saphira-cluster/    our C utility as an APK (builds the vendored
                             source tarball packed from this repo's
                             saphira-cluster/ directory)
saphira-cluster/ (repo)      Saphira management logic: C source, man page,
                             tests. Source code, not the package recipe.
docs/ (repo)                 policy, matrices, acceptance plan (generic names)
docs/examples/ (repo)        real-machine walkthroughs allowed (docs only)
runtime configuration        generated on the target, never committed
```

One owner per upstream man page: `slurm-doc` (a subpackage of the core
recipe) owns all upstream Slurm documentation including `slurmdbd(8)`
and `slurmdbd.conf(5)`, so installing `slurm-doc` beside
`slurm-accounting` can never collide. `slurm-accounting` ships no man
pages. `saphira-cluster-doc` owns our utility's man page.

## Leak check

Before commit, from the repo root:

```sh
grep -rniE "keeper|homer|minimer|akadata|saphira\.vm2|192\.168\.|10\.|fd[0-9a-f]{2}:" \
  /recipes/slurm /recipes/slurm-accounting /recipes/saphira-cluster \
  saphira-cluster \
  --exclude='*.tar.bz2*' --exclude='*.tar' | grep -v "^Binary"
```

Only the byte-identical upstream archives are excluded, never the
whole `files/` tree: units, init scripts and identity fragments are
scanned. `docs/examples/` is excluded: real
names are allowed there and only there. Any other hit is a defect.
