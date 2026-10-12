#!/bin/sh
# Slurm accounting companion: slurmdbd plus the mysql accounting
# plugin. Source-sharing sibling of recipes/slurm/recipe.sh: identical
# configure matrix except the documented mysql delta, so every output
# shares one plugin ABI (mariadb/mariadb-server precedent).
#
# Optional in use: nothing depends on this package, no compute node
# needs it, and a normal cluster runs without any database:
#   apk add slurm saphira-cluster
# Accounting only when asked for it:
#   apk add slurm-accounting
# Site-neutral; never enabled or started at install. All upstream
# documentation, including slurmdbd(8), stays owned by slurm-doc.

pkgname=slurm-accounting
pkgver=26.05.4
pkgrel=1
# r1: initial packaging. UNBUILT: no builder run yet. The builder trial
# must confirm mysql_config/mariadb_config presence in mariadb-dev;
# without it configure fails closed here by design (see below).
pkgarch=${SAPHIRA_ARCH:-x86_64}
pkgdesc="Slurm accounting daemon (optional companion)"
license="GPL-2.0-or-later"
origin=slurm-accounting
repo=saphira
url=https://slurm.schedmd.com/
source=https://github.com/SchedMD/slurm/releases/download/slurm-26-05-4-1/slurm-26.05.4.tar.bz2
sha256=035f4b193d4de979ba5381beca206a50b6b886b2793b06f68a1ce7e67022b06a

depends="
    mariadb
    slurm
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

recipe_build()
{
	cd "$SRC"
	slurm_configure
	make
}

# slurm_configure is defined in recipes/slurm/recipe.sh; the matrix is
# duplicated here verbatim plus the single documented delta so this
# recipe builds standalone. Delta: --with-mysql_config (core uses
# --without-mysql_config). Requesting it explicitly makes configure
# fail closed when the MariaDB development tooling is absent instead
# of silently building a dbd without database support.
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

recipe_install()
{
	make -C "$SRC" DESTDIR="$PKGDEST" install
	rm -rf "$PKGDEST/usr/lib/systemd"
	# Keep only the accounting payload: slurmdbd and the mysql
	# accounting plugin. Everything else (clients, other daemons,
	# plugins, docs) ships from slurm / slurm-doc.
	saved=$SRC/slurmdbd-split
	install -d "$saved/usr/sbin" "$saved/usr/lib/slurm"
	mv "$PKGDEST/usr/sbin/slurmdbd" "$saved/usr/sbin/"
	mv "$PKGDEST/usr/lib/slurm/accounting_storage_mysql.so" \
		"$saved/usr/lib/slurm/"
	rm -rf "$PKGDEST"/*
	install -d "$PKGDEST/usr/sbin" "$PKGDEST/usr/lib/slurm"
	mv "$saved"/usr/sbin/* "$PKGDEST/usr/sbin/"
	mv "$saved"/usr/lib/slurm/* "$PKGDEST/usr/lib/slurm/"
	# The example config for the one daemon owned here. All other
	# examples and every man page ship from slurm / slurm-doc, so this
	# package owns no documentation and cannot collide with slurm-doc.
	install -d -m 0755 "$PKGDEST/etc/slurm"
	install -m 0600 "$SRC/etc/slurmdbd.conf.example" \
		"$PKGDEST/etc/slurm/slurmdbd.conf.example"
	# Dual-init policy: both definitions ship unconditionally; neither
	# is enabled or started at install. slurmdbd cannot run without
	# the live slurmdbd.conf that saphira-cluster generates.
	install -D -m 0755 "$RECIPE_DIR/files/slurmdbd.initd" \
		"$PKGDEST/etc/init.d/slurmdbd"
	install -D -m 0644 "$RECIPE_DIR/files/slurmdbd.service" \
		"$PKGDEST/usr/lib/systemd/system/slurmdbd.service"
	for p in etc/init.d/slurmdbd \
			usr/lib/systemd/system/slurmdbd.service \
			etc/slurm/slurmdbd.conf.example \
			usr/sbin/slurmdbd \
			usr/lib/slurm/accounting_storage_mysql.so; do
		[ -e "$PKGDEST/$p" ] || \
			{ echo "ERROR: slurm-accounting payload is missing $p" >&2; return 1; }
	done
	# No man pages here by policy: slurmdbd(8) and slurmdbd.conf(5)
	# are owned by slurm-doc, the single documentation package for
	# the common upstream source.
	[ ! -e "$PKGDEST/usr/share/man" ] || \
		{ echo "ERROR: slurm-accounting must not ship man pages" >&2; return 1; }
}
