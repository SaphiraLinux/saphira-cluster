#!/bin/sh
# Scaffold CLI tests. Executed by the builder/host with a toolchain;
# NOT run by the agent during scaffolding (see README status).
# Usage: run.sh <path-to-saphira-cluster-binary>
set -eu

BIN=${1:?usage: run.sh <binary>}
fail=0

expect() { # expect <exit> <substring> <args...>
	want_exit=$1; want_text=$2; shift 2
	set +e
	out=$("$BIN" "$@" 2>&1)
	got_exit=$?
	set -e
	case $out in
		*"$want_text"*) text_ok=yes ;;
		*) text_ok=no ;;
	esac
	if [ "$got_exit" = "$want_exit" ] && [ "$text_ok" = yes ]; then
		echo "ok: $*"
	else
		echo "FAIL: $* (exit $got_exit, want $want_exit)"
		echo "$out" | head -5
		fail=1
	fi
}

expect 0 "usage:" --help
expect 0 "usage:" help
expect 0 "0.1.0" --version
expect 0 "0.1.0" version
expect 0 "cpu:" resources
expect 0 "memory:" resources
expect 0 "cgroup:" resources
expect 3 "not yet implemented" init testcluster --controller controller
expect 3 "not yet implemented" node add node01 --reserve-cpus 4
expect 3 "not yet implemented" apply
expect 3 "not yet implemented" status
expect 1 "unknown command" frobnicate

# doctor is environment-dependent: only its read-only banner is asserted.
set +e
"$BIN" doctor >doctor.out 2>&1
doctor_exit=$?
set -e
case $(head -1 doctor.out) in
	*"read-only"*) echo "ok: doctor banner" ;;
	*) echo "FAIL: doctor banner"; fail=1 ;;
esac
# doctor exits 0 (healthy) or 2 (findings); anything else is a crash.
case $doctor_exit in
	0|2) echo "ok: doctor exit $doctor_exit" ;;
	*) echo "FAIL: doctor exit $doctor_exit"; fail=1 ;;
esac
rm -f doctor.out

exit $fail
