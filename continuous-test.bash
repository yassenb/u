#!/bin/bash

while :; do
    inotifywait --quiet --quiet --excludei "\.swp" -e modify -e create -e delete -r src -r test
    # This sleep cures an odd bug with make using old timestamps
    sleep 0.1
    make
done
