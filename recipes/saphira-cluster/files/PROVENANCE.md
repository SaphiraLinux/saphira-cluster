# Provenance: saphira-cluster-0.1.0.tar

Packed from the `saphira-cluster/` source directory at the root of
this repository (same commit as the recipe). Contents:

- `Makefile` (developer convenience + `test` entry point)
- `src/` (the C utility)
- `tests/run.sh` (CLI harness, executed by `make test`)
- `saphira-cluster.8` (man page)

Excluded: `docs/` (not needed to build), any build scratch
(`saphira-cluster`, `test-scratch/` — never present in the tree).

Repack with:

```sh
rm -rf /tmp/sc-pack && mkdir -p /tmp/sc-pack/saphira-cluster
cp saphira-cluster/Makefile saphira-cluster/saphira-cluster.8 \
  /tmp/sc-pack/saphira-cluster/
cp -r saphira-cluster/src saphira-cluster/tests /tmp/sc-pack/saphira-cluster/
tar -cf recipes/saphira-cluster/files/saphira-cluster-0.1.0.tar \
  -C /tmp/sc-pack saphira-cluster
```

(Scratch outside the repo; the archive lands straight in `files/`.)
Then regenerate the `.sha256` sidecar (`sha256sum`, basename form)
and bump `pkgver`/`pkgrel` per policy. A repack with identical
sources must reproduce the recipe's `cd "$SRC/saphira-cluster"`
layout: top-level `saphira-cluster/` directory, nothing else.
