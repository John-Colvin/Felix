#!/usr/bin/env bash

set -euo pipefail

D_COMPILER=ldc-1.33.0-beta2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $SCRIPT_DIR
mkdir -p dlang
pushd dlang
[ -f ./install.sh ] || curl https://dlang.org/install.sh --output ./install.sh
bash ./install.sh $D_COMPILER --path .
ln -sf $D_COMPILER ldc
popd

#TODO go back to ninja once https://github.com/atilaneves/reggae/issues/194 is resolved
./dlang/ldc/bin/reggae --dc `pwd`/dlang/ldc/bin/ldmd2 -b make