#!/bin/bash

set -ex

mix deps.get
mix compile
mix setup

echo "run docker exec -it ${HOSTNAME} bash in another console to jump into the container!"

tail -f /dev/null
