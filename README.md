
# synology-docker-acme-sh

## Introduction

An elegant way to deploy certificates to DSM with temp admin credentials
created on the fly by acme.sh as described
[here](https://github.com/acmesh-official/acme.sh/wiki/deployhooks#20-deploy-the-certificate-to-synology-dsm),
but from acme.sh inside a docker container.

This approach avoids potential issues with a local acme.sh install that is
known to break on updates as well as makes it unnecessary to configure
Synology-side cron task as the acme.sh container will simply use its own
cron daemon.

## How it works

The trick resolves around the wrapper script `in_host.sh` together with a
privileged container that shares the PID namespace of the host. (The network
namespace is also shared, but that's just a minor optimization, since it does
not make sense to isolate acme.sh further in an own network.)

The wrapper script can be mapped in the container at the same path as a host
synology tool and then wraps that tool in a `nsenter` call inside the host
network, mount and IPC namespaces accessible via PID 1 in the shared PID
namespace. This allows the synology tools to access all required resources
as they are essentially executing directly on the host as before.

As a side note, the script benefits from the fact that `nsenter` is already
installed by default in alpine images, so we do not even need to install new
packages - always a plus in my opinion.

## Deploying

For issuing and deploying, acme.sh can be invoked as usual with `docker compose exec`,
e.g. for deploying

```bash
docker-compose exec \
    -e SYNO_CERTIFICATE="your.domain" \
    -e SYNO_CREATE=0/1 \
    acme \
    acme.sh --deploy --deploy-hook synology_dsm -d your.domain
```

From my experience, it is worthwhile to consider also using the optional
environment variables `SYNO_CERTIFICATE` and `SYNO_CREATE`:

`SYNO_CERTIFICATE` allows to specify a cert by its description and thereby
easily allows managing multiple certificates, e.g. when using the reverse proxy
feature. Without description every deployment would otherwise always replace
the default web interface certificate.

`SYNO_CREATE` additionally allows to ensure that only certificates that already
exist will be replaced. For me, `SYNO_CREATE=0` serves as an additional safeguard
after the first deployment of a certificate to ensure that only this specific
certificate will then get replaced. This hopefully does ensure that not the
default certificate with an empty description will get accidentially created
again - or alternatively new certificates will be created by accident.
