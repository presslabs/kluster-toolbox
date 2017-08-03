#!/bin/bash
set -e
source /usr/local/bin/setup-credentials-helper.sh

: ${RELEASE_NAME:="$PLUGIN_RELEASE_NAME"}
: ${CHART:="$PLUGIN_CHART"}

: ${GIT_CRYPT_KEY_URL:="$PLUGIN_GIT_CRYPT_KEY_URL"}

if [ ! -z "$GIT_CRYPT_KEY_URL" ] ; then
    /usr/local/bin/git-crypt-unlock-helper.sh "$GIT_CRYPT_KEY_URL"
fi

: ${PLUGIN_NAMESPACE:="default"}
: ${NAMESPACE:="$PLUGIN_NAMESPACE"}
if [ -z "$1" ] ; then
    require_param "namespace"
    require_param "chart"
    require_param "release_name"
    /usr/local/bin/helm-wrapper
else
    exec "$@"
fi
