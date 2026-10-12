#!/bin/sh
# Slurm accounting daemon. Source-sharing sibling of slurm/recipe.sh:
# identical configure matrix (one plugin ABI), file-pruned at install
# to the slurmdbd/sackd payload plus its dual-init definitions.
#
# Packaged from day one, optional in use: nothing enables it, and the
# client/controller/compute outputs never depend on it, so a four-node
# cluster runs without any database. Site-neutral; never enabled or
# started at install.

pkgname=slurm-slurmdbd
pkgver=26.05.4
pkgrel=1
# r1: initial packaging. UNBUILT, same builder-trial caveat as slurm r1,
# plus: the mysql accounting plugin needs mysql_config in mariadb-dev;
# if it is absent the builder trial decides between packaging a
# mysql_config shim with MariaDB or revisiting this output.
pkgarch=${SAPHIRA_ARCH:-x86_64}
pkgdesc="Slurm accounting daemon (optional)"
license="GPL-2.0-or-later"
origin=slurm-slurmdbd
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

# slurm_configure is defined in slurm/recipe.sh; the matrix is
# duplicated here verbatim so this recipe builds standalone.
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
	# Keep the dbd payload: slurmdbd, the accounting-cache sackd, and
	# the mysql accounting plugin (pruned from the slurm output).
	saved=$SRC/slurmdbd-split
	install -d "$saved/usr/sbin" "$saved/usr/lib/slurm"
	mv "$PKGDEST/usr/sbin/slurmdbd" "$saved/usr/sbin/"
	mv "$PKGDEST/usr/sbin/sackd" "$saved/usr/sbin/"
	mv "$PKGDEST/usr/lib/slurm/accounting_storage_mysql.so" \
		"$saved/usr/lib/slurm/"
	rm -rf "$PKGDEST"/*
	install -d "$PKGDEST/usr/sbin" "$PKGDEST/usr/lib/slurm"
	mv "$saved"/usr/sbin/* "$PKGDEST/usr/sbin/"
	mv "$saved"/usr/lib/slurm/* "$PKGDEST/usr/lib/slurm/"
	# Dual-init policy: both definitions ship unconditionally; neither
	# is enabled or started at install. slurmdbd cannot run without
	# its config, so both definitions require the live slurmdbd.conf
	# that saphira-cluster generates on the target.
	install -D -m 0755 "$RECIPE_DIR/files/slurmdbd.initd" \
		"$PKGDEST/etc/init.d/slurmdbd"
	install -D -m 0644 "$RECIPE_DIR/files/slurmdbd.service" \
		"$PKGDEST/usr/lib/systemd/system/slurmdbd.service"
	# sackd (auth/cred kiosk) ships with the accounting family in r1;
	# its compute-node placement is a documented follow-up question.
	install -D -m 0755 "$RECIPE_DIR/files/sackd.initd" \
		"$PKGDEST/etc/init.d/sackd"
	install -D -m 0644 "$RECIPE_DIR/files/sackd.service" \
		"$PKGDEST/usr/lib/systemd/system/sackd.service"
	for p in etc/init.d/slurmdbd etc/init.d/sackd \
			usr/lib/systemd/system/slurmdbd.service \
			usr/lib/systemd/system/sackd.service \
			usr/sbin/slurmdbd usr/sbin/sackd \
			usr/lib/slurm/accounting_storage_mysql.so; do
		[ -e "$PKGDEST/$p" ] || \
			{ echo "ERROR: slurm-slurmdbd payload is missing $p" >&2; return 1; }
	done
}
