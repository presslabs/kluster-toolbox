#!/bin/bash
set -eo pipefail

plugin="$1"
plugin_version="$2"

if [[ "$plugin" == http://* ]] || [[ "$plugin" == https://* ]] ; then
    plugin_url="$plugin"
else
    plugin_url="https://releases.hashicorp.com/${plugin}/${plugin_version}/${plugin}_${plugin_version}_linux_amd64.zip"
fi

if [[ "$plugin_url" == *.zip ]] ; then
    wget "$plugin_url" -O"/tmp/plugin.zip"
    unzip "/tmp/plugin.zip" -d "/usr/lib/terraform-plugins"
    rm "/tmp/plugin.zip"
elif [[ "$plugin_url" == *.tar.gz ]] ; then
    wget "$plugin_url" -O"/tmp/plugin.tar.gz"
    tar -zxf "/tmp/plugin.tar.gz" -C /usr/lib/terraform-plugins --strip-components=1
    rm "/tmp/plugin.tar.gz"
else
    echo "Unknown extesion for url $plugin_url"
    exit 1
fi

