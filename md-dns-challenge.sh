#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# md-dns-challenge.sh
#
# https://github.com/furplag/certbot-dns
# Copyright 2017 furplag
# Licensed under Apache 2.0 (https://github.com/furplag/certbot-dns/blob/master/LICENSE)

###
# variables
# - CLOUDFLARE_AUTH_KEY : Cloudflare API param: "X-Auth-Key"
# - CLOUDFLARE_AUTH_EMAIL : Cloudflare API param: "X-Auth-Email"
#
# see more information : "DNS Records for a Zone" section at https://api.cloudflare.com/ .

export CLOUDFLARE_AUTH_KEY=${CLOUDFLARE_AUTH_KEY:-}
export CLOUDFLARE_AUTH_EMAIL=${CLOUDFLARE_AUTH_EMAIL:-}

declare -r _basedir=$(cd $(dirname $0)/;pwd)
declare -r _function=${1:-}

if [[ "${_function}" = 'setup' ]]; then
  cat <<_EOT_ |bash
export CERTBOT_DOMAIN="${2:-}";
export CERTBOT_VALIDATION="${3:-}";

source <(cat $_basedir/authenticator.sh);
_EOT_;
elif [[ "${_function}" = 'teardown' ]]; then
  cat <<_EOT_ |bash
export CERTBOT_DOMAIN="${2:-}";

source <(cat $_basedir/cleanup.sh);
_EOT_;
else echo "invaild argment, there is no function \"${_function}\" ."; fi
