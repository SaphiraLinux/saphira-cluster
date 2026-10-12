# Developer convenience only. The Saphira package build, when this
# becomes a recipe, goes through the builder like everything else;
# this Makefile never substitutes for it.
CC = gcc
CFLAGS = -std=c89 -pedantic -Wall -Wextra -O2
SRC = src/main.c src/usage.c src/resources.c src/doctor.c src/util.c

all: saphira-cluster

saphira-cluster: $(SRC) src/cluster.h
	$(CC) $(CFLAGS) -o $@ $(SRC)

check:
	@for f in $(SRC); do $(CC) $(CFLAGS) -fsyntax-only $$f || exit 1; done
	@echo "syntax OK"

clean:
	rm -f saphira-cluster
