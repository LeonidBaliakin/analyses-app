#!/bin/sh
set -eu
python3 /worker/make_config.py /runtime/manifest.json /tmp/processing-config.json
exec /app/processing
