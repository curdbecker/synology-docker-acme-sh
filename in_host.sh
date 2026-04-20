#!/bin/sh

exec nsenter -t 1 --net --mount --ipc "$0" "${@}"
