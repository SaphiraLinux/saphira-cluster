#!/bin/sh
# Slurm controller daemon. Source-sharing sibling of slurm/recipe.sh:
# identical configure matrix (one plugin ABI), file-pruned at install
# to the slurmctld payload plus its dual-init definitions.
# Site-neutral; never enabled or started at install.

pkgname=slurm-slurmctld
pkgver=26.05.4
pkgrel=1
# r1: initial packaging. UNBUILT, same builder-trial caveat as slurm r1.
pkgarch=${SAPHIRA_ARCH:-x86_64}
pkgdesc="Slurm controller daemon"
license="GPL-2.0-or-later"
origin=slurm-slurmctld
repo=saphira
url=https://slurm.schedmd.com/
source=https://github.com/SchedMD/slurm/releases/download/slurm-26-05-4-1/slurm-26.05.4.tar.bz2
sha256=035f4b193d4de979ba5381beca206a50b6b886b2793b06f68a1ce7e67022b06a

depends="
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
	# Keep only the slurmctld payload.
	saved=$SRC/slurmctld-split
	install -d "$saved/usr/sbin"
	mv "$PKGDEST/usr/sbin/slurmctld" "$saved/usr/sbin/"
	rm -rf "$PKGDEST"/*
	install -d "$PKGDEST/usr/sbin"
	mv "$saved"/usr/sbin/* "$PKGDEST/usr/sbin/"
	# Dual-init policy: both definitions ship unconditionally; neither
	# is enabled or started at install. The controller cannot run
	# without its config, so both definitions require the live
	# slurm.conf that saphira-cluster generates on the target.
	install -D -m 0755 "$RECIPE_DIR/files/slurmctld.initd" \
		"$PKGDEST/etc/init.d/slurmctld"
	install -D -m 0644 "$RECIPE_DIR/files/slurmctld.service" \
		"$PKGDEST/usr/lib/systemd/system/slurmctld.service"
	for p in etc/init.d/slurmctld \
			usr/lib/systemd/system/slurmctld.service \
			usr/sbin/slurmctld; do
		[ -e "$PKGDEST/$p" ] || \
			{ echo "ERROR: slurm-slurmctld payload is missing $p" >&2; return 1; }
	done
}
