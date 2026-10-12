# Developer convenience only. The Saphira package build, when this
# becomes a recipe, goes through the builder like everything else;
# this Makefile never substitutes for it.
CC = gcc
CFLAGS = -std=c89 -pedantic -Wall -Wextra -O2
PREFIX = /usr
DESTDIR =
SRC = src/main.c src/usage.c src/resources.c src/doctor.c src/util.c

all: saphira-cluster

saphira-cluster: $(SRC) src/cluster.h
	$(CC) $(CFLAGS) -o $@ $(SRC)

check:
	@for f in $(SRC); do $(CC) $(CFLAGS) -fsyntax-only $$f || exit 1; done
	@echo "syntax OK"

# Packaged test entry point: builds to scratch (never into the source
# tree) and runs the CLI harness against the fresh binary. The recipe
# invokes `make test` in recipe_build.
test:
	rm -rf test-scratch
	mkdir -p test-scratch
	$(CC) $(CFLAGS) -o test-scratch/saphira-cluster $(SRC)
	sh tests/run.sh test-scratch/saphira-cluster
	rm -rf test-scratch

# Packaged install entry point (PREFIX/DESTDIR-aware). The recipe
# invokes `make DESTDIR="$PKGDEST" install`.
install: saphira-cluster
	install -D -m 0755 saphira-cluster \
		$(DESTDIR)$(PREFIX)/sbin/saphira-cluster
	install -D -m 0644 saphira-cluster.8 \
		$(DESTDIR)$(PREFIX)/share/man/man8/saphira-cluster.8

clean:
	rm -f saphira-cluster
	rm -rf test-scratch
