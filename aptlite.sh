#!/bin/bash

start_time=$(date+%s)

PACKAGE_NAME=$1

total.sh "$PACKAGE_NAME"

python3 deporder.py

install.sh

finish_time=$(date+%s)

echo "Time duration:$((finish_time-start_time)) secs."
