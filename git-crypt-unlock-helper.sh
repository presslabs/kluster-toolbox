#!/bin/bash
GIT_CRYPT_KEY="$(mktemp)"
gsutil -q cp "$1" "$GIT_CRYPT_KEY"
echo "+ git-crypt unlock $GIT_CRYPT_KEY"
git-crypt unlock "$GIT_CRYPT_KEY"
rm -f "$GIT_CRYPT_KEY"
