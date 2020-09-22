#!/bin/sh

# This script converts SHOW GLOBALS STATUS into a tabulated format, one line
# per sample in the input, with the metrics divided by the time elapsed
# between samples.

awk '
	BEGIN {
		printf "#ts date time load QPS";
		fmt = " %.2f";
	}
	/^TS/ { # The timestamp lines begin with TS.
		ts		= substr($2, 1, index($2, ".") - 1);
		load	= NF - 2;
	    diff	= ts - prev_ts;
		prev_ts = ts;
	    printf "\n%s %s %s %s", ts, $3, $4, substr($load, 1, length($load) - 1);
	}
	/Queries/ {
		printf fmt, ($2-Queries)/diff;
		Queries=$2
	}
	' "$@"

# Usage:
#	./analyze.sh 5-sec-status-2020-08-01_07-status
#
