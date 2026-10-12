#!/bin/sh
# saphira-cluster: native Saphira control utility for Slurm. Discovers
# local capability, applies the service-reservation policy, generates
# and validates Slurm configuration, manages enrolment and reports
# cluster state. It is not a scheduler.
#
# Second product in this repo (Slurm is the first); the optional
# slurm-accounting companion is a third recipe, not a third product.
# Builds from the vendored source tarball packed out of this repo's
# saphira-cluster/ directory (see files/PROVENANCE.md).

pkgname=saphira-cluster
pkgver=0.1.0
pkgrel=1
# r1: initial packaging. UNBUILT: no builder run yet.
pkgarch=${SAPHIRA_ARCH:-x86_64}
pkgdesc="Saphira cluster control utility for Slurm"
license="MIT"
origin=saphira-cluster
repo=saphira
url=https://github.com/SaphiraLinux/saphira-cluster
source=saphira-cluster-0.1.0.tar
sha256=a99fb730fa96089bfb828e891a53d33390aca96164db1486ebe1bf62fa1d3e63

depends=""

makedepends="
    binutils
    gcc
    make
"

subpackages="saphira-cluster-doc"

# No hard dependency on slurm: resources/doctor are useful on any
# host, and both degrade gracefully when Slurm is absent. Operators
# compose `apk add slurm saphira-cluster` (plus slurm-accounting only
# when accounting is wanted).

recipe_build()
{
	cd "$SRC/saphira-cluster"
	make
	# The CLI harness runs here, in the build: a binary that fails
	# its own tests must not become a package.
	make test
}

recipe_install()
{
	make -C "$SRC/saphira-cluster" DESTDIR="$PKGDEST" install
	[ -x "$PKGDEST/usr/sbin/saphira-cluster" ] || \
		{ echo "ERROR: saphira-cluster payload is missing the binary" >&2; return 1; }
	[ -e "$PKGDEST/usr/share/man/man8/saphira-cluster.8" ] || \
		{ echo "ERROR: saphira-cluster payload is missing the man page" >&2; return 1; }
}
