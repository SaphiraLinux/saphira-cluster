#!/bin/sh
# Slurm workload manager: client tools, shared libraries and plugins.
#
# Daemon binaries ship from the source-sharing slurm-slurmd,
# slurm-slurmctld and slurm-slurmdbd recipes in this repo (identical
# configure matrix, file-pruned at install; mariadb/mariadb-server
# precedent). This keeps MariaDB client libraries and any future
# daemon-only dependencies off plain client/compute images.
#
# Site-neutral: no hostnames, addresses, topology or cluster policy
# anywhere in this recipe. Shipped configuration is upstream examples
# only; live slurm.conf/gres.conf/cgroup.conf are generated on the
# target by saphira-cluster and never committed or shipped.

pkgname=slurm
pkgver=26.05.4
pkgrel=1
# r1: initial Slurm packaging. UNBUILT: no builder run yet; every flag
# below is proven against the vendored 26.05.4 ./configure --help and
# slurm.spec, not against a build log. Builder trial must confirm in
# particular: mysql_config presence in mariadb-dev (dbd recipe),
# --enable-cgroupv2 header requirements, and hwloc/json-c/lz4/readline
# autodetection.
pkgarch=${SAPHIRA_ARCH:-x86_64}
pkgdesc="Slurm workload manager (client tools, libraries and plugins)"
license="GPL-2.0-or-later"
origin=slurm
repo=saphira
url=https://slurm.schedmd.com/
source=https://github.com/SchedMD/slurm/releases/download/slurm-26-05-4-1/slurm-26.05.4.tar.bz2
sha256=035f4b193d4de979ba5381beca206a50b6b886b2793b06f68a1ce7e67022b06a

depends="
    hwloc
    json-c
    lz4
    readline
    saphira-base-accounts
"

makedepends="
    binutils
    gawk
    gcc
    hwloc-dev
    json-c-dev
    lz4-dev
    make
    mariadb-dev
    perl
    pkgconf
    readline-dev
"

subpackages="slurm-dev slurm-doc"

# Shared configure matrix for all four Slurm recipes in this repo.
# Any flag change here must be mirrored in slurm-slurmd,
# slurm-slurmctld and slurm-slurmdbd so every output shares one plugin
# ABI. Rationale per flag (see docs/build-matrix.md):
# --sysconfdir=/etc/slurm: upstream RPM layout; compiled-in default
#   config path, so saphira-cluster writes exactly one well-known path.
# --runstatedir=/var/run: Saphira volatile runtime root (real dir,
#   never an alias of /run).
# --without-rpath, --disable-x11/--disable-gtktest/--disable-sview:
#   headless, no desktop stack.
# --enable-cgroupv2: load-bearing for resource isolation; explicit so a
#   missing header fails closed instead of silently disabling it.
# --disable-slurmrestd: needs libjwt + an HTTP parser library, neither
#   packaged yet; restd is a documented follow-up, not silent breakage.
# --without-munge: MUNGE is not packaged yet; auth/slurm is built in
#   and both mechanisms are proven before a default is declared.
# --without-pmix: external PMIx is not packaged yet; built-in
#   mpi/pmi2 plumbing is unaffected. PMIx runtime is a follow-up.
# --with-hwloc/--with-json/--with-lz4/--with-readline: packaged deps,
#   topology detection, CLI completion, JSON output.
# --with-mysql_config: enables slurmdbd + the mysql accounting plugin
#   (pruned from this output, kept by slurm-slurmdbd).
# --without-systemdsystemunitdir: upstream units are never installed;
#   each daemon recipe ships its own dual-init definitions.
slurm_configure()
{
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc/slurm \
		--localstatedir=/var \
		--runstatedir=/var/run \
		--libdir=/usr/lib \
		--without-rpath \
		--without-systemdsystemunitdir \
		--enable-pkgconfig \
		--enable-cgroupv2 \
		--disable-x11 \
		--disable-gtktest \
		--disable-sview \
		--disable-slurmrestd \
		--without-munge \
		--without-pmix \
		--with-hwloc \
		--with-json \
		--with-lz4 \
		--with-readline \
		--with-mysql_config=/usr/bin
}

recipe_build()
{
	cd "$SRC"
	slurm_configure
	make
}

recipe_install()
{
	make -C "$SRC" DESTDIR="$PKGDEST" install
	# Upstream units are never installed (see configure matrix);
	# prune whatever arrives anyway so only owned definitions ship.
	rm -rf "$PKGDEST/usr/lib/systemd"
	# This output owns no daemon: prune daemon binaries, which ship
	# from the source-sharing daemon recipes.
	rm -f "$PKGDEST/usr/sbin/slurmctld" "$PKGDEST/usr/sbin/slurmd" \
		"$PKGDEST/usr/sbin/slurmstepd" "$PKGDEST/usr/sbin/slurmdbd" \
		"$PKGDEST/usr/sbin/sackd"
	# The mysql accounting plugin belongs with slurm-slurmdbd.
	rm -f "$PKGDEST/usr/lib/slurm/accounting_storage_mysql.so"
	# Generic upstream examples only; never a live cluster config.
	install -d -m 0755 "$PKGDEST/etc/slurm"
	for example in cgroup.conf cli_filter.lua job_submit.lua prolog \
			slurm.conf; do
		install -m 0644 "$SRC/etc/$example.example" \
			"$PKGDEST/etc/slurm/$example.example"
	done
	install -m 0600 "$SRC/etc/slurmdbd.conf.example" \
		"$PKGDEST/etc/slurm/slurmdbd.conf.example"
	# Service identity declaration (single owner: this package; the
	# daemon recipes depend on slurm so identities exist before any
	# daemon is installed). slurm:111 is a new Saphira allocation in
	# the 0..199 package range, documented here per namespace policy.
	# State dirs: ctld state (slurm-owned), slurmd spool (root-owned,
	# slurmd runs as root), shared log dir.
	install -D -m 0644 "$RECIPE_DIR/files/accounts.d/slurm" \
		"$PKGDEST/usr/share/saphira/accounts.d/slurm"
}
