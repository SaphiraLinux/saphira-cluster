# Slurm 26.05.4 build matrix (r1)

Decided before building so a needed plugin is never discovered missing
six months later. "Build" means compiled in; "runtime" means required
to run. The two are kept deliberately separate.

## r1: build in (core recipe)

- cgroup v2 (`--enable-cgroupv2`, explicit/fail-closed).
- Configless operation (`SlurmctldParameters=enable_configless` is a
  runtime default in generated configs; no build flag needed).
- `auth/slurm` (built in, no extra dependency).
- hwloc topology (`--with-hwloc`).
- JSON output (`--with-json`), lz4 (`--with-lz4`), readline CLI
  (`--with-readline`).
- Built-in `mpi/pmi2` launch plumbing (no external dependency).
- GPU GRES autodetect paths as upstream builds them by default; no
  CUDA toolkit at build time.
- PAM module: default (not forced; `--enable-pam` needs a proven
  `pam_dir` first).
- Explicitly **no** MySQL (`--without-mysql_config`): without the flag
  configure auto-searches for `mysql_config`/`mariadb_config`, so the
  flag is what keeps core deterministically database-free. Verified in
  `auxdir/x_ac_databases.m4`; the recipe fails the build if any MySQL
  artifact appears in the core payload.

## The one matrix delta: slurm-accounting

`recipes/slurm-accounting` uses the identical matrix plus
`--with-mysql_config=/usr/bin`, which makes configure fail closed when
the MariaDB development tooling is absent. The delta gates only
`slurmdbd` and `accounting_storage_mysql.so` — nothing in the core
plugin set — so both outputs share one plugin ABI.

## r1: deliberately out (follow-up packages, not silent gaps)

- `slurmrestd` (`--disable-slurmrestd`): needs `libjwt` + an HTTP
  parser (`llhttp` or `libhttp-parser`), neither packaged yet.
  REST API is a follow-up, not a surprise.
- MUNGE plugin (`--without-munge`): MUNGE itself is unpackaged.
  `auth/slurm` and MUNGE are both proven before a default is declared.
- External PMIx (`--without-pmix`): needs a `pmix` package; the
  built-in PMI1/PMI2 path is unaffected. MPI runtimes (OpenMPI/PMIx)
  are the next packages beside this one, not another framework.
- YAML output: needs `libyaml` (unpackaged).
- Lua plugins: needs a proven lua `pkg-config` name (`lua54` exists;
  Slurm's lua detection is unproven against it).
- libcurl extras, freeIPMI, HDF5, UCX/OFED, s2n/TLS extras: unpackaged
  or unneeded for v1; each is a separate decision with its own deps.

## Runtime dependency discipline

- `slurm` (core: clients, ctld, slurmd, sackd): hwloc, json-c, lz4,
  readline only. Never MariaDB.
- `slurm-accounting` (slurmdbd + mysql plugin): `slurm` + `mariadb`.
- No compute node ever depends on MariaDB because an optional plugin
  was compiled in. Documentation ownership: `slurm-doc` owns every
  upstream man page including `slurmdbd(8)`; `slurm-accounting` ships
  none.

## Cluster levels (for documentation)

- Level 1, distributed jobs: independent jobs land on free nodes.
  Slurm alone suffices.
- Level 2, parallel jobs: one job spans nodes via MPI/PMIx. Needs the
  MPI runtime packages next.
- Level 3, accelerated parallel jobs: CPUs + GPUs across nodes via
  MPI/NCCL/UCX or application fabrics. Needs shared storage and
  interconnect decisions first.
