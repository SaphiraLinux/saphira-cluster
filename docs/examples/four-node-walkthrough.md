# Example: four-node reserved-capacity cluster (documentation only)

> This walkthrough names real machines as an illustration. It is
> documentation, not package policy: nothing here enters `recipe.sh`,
> units, tests or generated defaults. See `docs/boundary.md`.

```sh
saphira-cluster init akadata --controller keeper

saphira-cluster node add homer \
    --reserve-cpus 4 \
    --reserve-memory 32G \
    --gpu auto \
    --gpu-share mps:100

saphira-cluster node add keeper \
    --reserve-cpus 2 \
    --reserve-memory 8G

saphira-cluster node add minimer \
    --reserve-cpus 1 \
    --reserve-memory 4G

saphira-cluster node add route --no-exec

saphira-cluster apply
saphira-cluster status
```

- `keeper` runs `slurmctld` (and may also compute within its advertised
  remainder).
- `homer` computes within total-minus-4-CPUs/32G; its GPU is whole-device
  scheduled until the MPS gate passes.
- `minimer` is a small compute node; its ZFS datasets back local job
  spool, not shared storage.
- `route --no-exec` participates administratively but never runs jobs.

Jobs stay boring:

```sh
srun -N1 -c4 make -j4
srun --gres=gpu:1 ./cuda-job
```

Shared-GPU (`--gres=mps:25`) waits for the MPS gate. Harvesting
whatever happens to be idle waits for its own design.
