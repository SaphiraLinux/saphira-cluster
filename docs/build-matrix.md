# Slurm 26.05.4 build matrix (r1)

Decided before building so a needed plugin is never discovered missing
six months later. "Build" means compiled in; "runtime" means required
to run. The two are kept deliberately separate.

## r1: build in

- cgroup v2 (`--enable-cgroupv2`, explicit/fail-closed).
- Configless operation (`SlurmctldParameters=enable_configless` is a
  runtime default in generated configs; no build flag needed).
- `auth/slurm` (built in, no extra dependency).
- MariaDB accounting plugin + `slurmdbd` (via `--with-mysql_config`;
  builder trial must confirm `mysql_config` in `mariadb-dev`).
- hwloc topology (`--with-hwloc`).
- JSON output (`--with-json`), lz4 (`--with-lz4`), readline CLI
  (`--with-readline`).
- Built-in `mpi/pmi2` launch plumbing (no external dependency).
- GPU GRES autodetect paths as upstream builds them by default; no
  CUDA toolkit at build time.
- PAM module: default (not forced; `--enable-pam` needs a proven
  `pam_dir` first).

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

- `slurm` (client): hwloc, json-c, lz4, readline only.
- `slurm-slurmd`, `slurm-slurmctld`: `slurm` only.
- `slurm-slurmdbd`: `slurm` + `mariadb`.
- No compute node ever depends on MariaDB or NVIDIA libraries because
  an optional plugin was compiled in.

## Cluster levels (for documentation)

- Level 1, distributed jobs: independent jobs land on free nodes.
  Slurm alone suffices.
- Level 2, parallel jobs: one job spans nodes via MPI/PMIx. Needs the
  MPI runtime packages next.
- Level 3, accelerated parallel jobs: CPUs + GPUs across nodes via
  MPI/NCCL/UCX or application fabrics. Needs shared storage and
  interconnect decisions first.
