#!/bin/sh

filename=$1

if [ -z "$filename" ]; then
    echo "Usage: $0 FILENAME"
    echo ""
    echo "Example: $0 day_01"
else
    ghdl -a --std=08 --workdir=workdir src/$filename.vhd \
    && ghdl -e --std=08 --workdir=workdir -o workdir/$filename $filename \
    && workdir/$filename --max-stack-alloc=0
fi
