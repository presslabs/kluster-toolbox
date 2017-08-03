#!/bin/bash
: ${GOOGLE_CREDENTIALS:="$(cat "$PLUGIN_GOOGLE_CREDENTIALS_FILE" 2>/dev/null)"}
: ${PROJECT:="$PLUGIN_PROJECT"}
: ${CLUSTER:="$PLUGIN_CLUSTER"}
: ${ZONE:="$PLUGIN_ZONE"}
: ${UPGRADE_TILLER:="$PLUGIN_UPGRADE_TILLER"}

require_param() {
    declare name="$1"
    local env_name
    env_name="$(echo "$name" | tr /a-z/ /A-Z/)"
    if [ -z "${!env_name}" ] ; then
        echo "You must define \"$name\" parameter or define $env_name environment variable" >&2
        exit 2
    fi
}

run() {
    echo "+" "$@"
    "$@"
}

if [ -z "$GOOGLE_CREDENTIALS" ] ; then
    echo "You must define \"google_credentials_file\" parameter or define GOOGLE_CREDENTIALS environment variable" >&2
    exit 2
fi

if [ ! -z "$GOOGLE_CREDENTIALS" ] ; then
    echo "$GOOGLE_CREDENTIALS" > /run/google-credentials.json
    gcloud auth activate-service-account --key-file=/run/google-credentials.json
fi

if [ ! -z "$CLUSTER" ] ; then
    echo "cluster: $CLUSTER"
    require_param "cluster"
    require_param "project"
    require_param "zone"

    run gcloud container clusters get-credentials core --project "$PROJECT" --zone "$ZONE"
    # Display kubernetees versions (usefull for debugging)
    run kubectl version

    # initialize helm
    if [ "$UPGRADE_TILLER" == "true" ] || [ "$UPGRADE_TILLER" == "yes" ]; then
        run helm init --upgrade
    fi
fi

run helm init --client-only
# Display helm version (usefull for debugging)
run helm version -c
run helm version -s || true
