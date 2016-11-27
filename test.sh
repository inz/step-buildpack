#!/bin/bash

set -e

export WERCKER_BUILDPACK_BUILD_DEBUG=true

for dir in test/*; do
  pushd $dir
  ../../run.sh
  popd
done

echo "All done."