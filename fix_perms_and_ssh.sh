#!/bin/sh

set -e

# don't fall into our own redirection
export PATH=/bin:/usr/bin/:/sbin:/usr/sbin

chmod u=rw,go= /root/.ssh/*
exec ssh "${@}"
