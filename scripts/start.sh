#!/bin/bash

set -ex

mix deps.get
mix setup
mix phx.server
