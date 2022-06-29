#!/bin/bash

set -e

if [[ $1 = "devel" ]]; then
    exec tail -f /dev/null
else
    exec $@
fi