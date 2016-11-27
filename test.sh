#!/bin/bash

set -e

for dir in test/*; do
  pushd $dir
  ../../run.sh
  popd
done

echo "All done."