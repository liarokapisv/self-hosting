#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p etc/ssh
ssh-keygen -t ed25519 -C "" -q -P "" -f etc/ssh/ssh_host_ed25519_key
cp -r $SCRIPT_DIR/secrets secrets
pushd secrets

script --return --quiet /dev/null <<EOF
AGENIX_ENCRYPTION_KEY="$(cat ../etc/ssh/ssh_host_ed25519_key.pub)" agenix -r
EOF

popd
