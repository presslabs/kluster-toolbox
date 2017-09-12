#!/bin/bash
set -e
source /usr/local/bin/setup-credentials-helper.sh

: ${GIT_CRYPT_KEY_URL:="$PLUGIN_GIT_CRYPT_KEY_URL"}
if [ ! -z "$GIT_CRYPT_KEY_URL" ] ; then
    /usr/local/bin/git-crypt-unlock-helper.sh "$GIT_CRYPT_KEY_URL"
fi

if [ -z "$1" ] ; then
    exec "/bin/sh"
else
    exec "$@"
fi
