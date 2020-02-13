#!/usr/bin/env bash

set -e

CACHE_DIR=$HOME/or-tools/$OR_TOOLS_VERSION

if [ ! -d "$CACHE_DIR" ]; then
  wget https://github.com/google/or-tools/releases/download/v7.5/or-tools_ubuntu-18.04_v$OR_TOOLS_VERSION.tar.gz
  tar xvf or-tools_ubuntu-18.04_v$OR_TOOLS_VERSION.tar.gz
  mv or-tools_Ubuntu-18.04-64bit_v$OR_TOOLS_VERSION $CACHE_DIR
else
  echo "OR-Tools cached"
fi
