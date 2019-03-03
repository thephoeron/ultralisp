#!/bin/bash

set -e
set -x

if [[ "$MODE" == "worker" ]]; then
    /usr/bin/supervisord --nodaemon
else
    /app/ultralisp-server \
        | tee -a /app/logs/app.log \
        | jsail
fi
