#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# cleanup.sh
# 
# https://github.com/furplag/certbot-dns
# Copyright 2017 furplag
# Licensed under Apache 2.0 (https://github.com/furplag/certbot-dns/blob/master/LICENSE)
# 
# forked from https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks

###
# variables
# - CLOUDFLARE_AUTH_KEY : Cloudflare API param: "X-Auth-Key"
# - CLOUDFLARE_AUTH_EMAIL : Cloudflare API param: "X-Auth-Email"
# important : You should write those in /etc/sysconfig/certbot .
#
# see more information : "DNS Records for a Zone" section at https://api.cloudflare.com/ .

###
# statics
declare -r _baseUrl=https://api.cloudflare.com/client/v4/zones
declare -r _auth_key=${CLOUDFLARE_AUTH_KEY:-}
declare -r _email=${CLOUDFLARE_AUTH_EMAIL:-}

declare -r _tld=$(expr match "${CERTBOT_DOMAIN}" '.*\.\(.*\..*\)')
declare -r _domain_root=${_tld:-$CERTBOT_DOMAIN}
declare -r _domain=$(echo "${_domain_root}" | sed -e "s/^\*\.//")

declare -r _logDir=/var/log/letsencrypt
declare -r _datetime=`date +"%Y%m%d%H%M%S"`
declare -r _log=${_logDir}/cleanupFailure.${_datetime}.log

[ -d $_logDir ] || mkdir -p $_logDir;
if [[ -z "${_auth_key}" ]]; then echo "failure : invalid argument \"CLOUDFLARE_AUTH_KEY\" ( \"${CLOUDFLARE_AUTH_KEY}\" ) ." >>$_log; exit 1; fi
if [[ -z "${_email}" ]]; then echo "failure : invalid argument \"CLOUDFLARE_AUTH_EMAIL\" ( \"${CLOUDFLARE_AUTH_EMAIL}\" ) ." >>$_log; exit 1; fi
if [[ -z "${_domain}" ]]; then echo "failure : invalid argument \"CERTBOT_DOMAIN\" ( \"${CERTBOT_DOMAIN}\" ) ." >>$_log; exit 1; fi
if [[ "${_domain}" =~ \* ]]; then echo "failure : invalid argument \"CERTBOT_DOMAIN\" ( \"${CERTBOT_DOMAIN}\" ) ." >>$_log; exit 1; fi

# get zone ID .
ZONE_ID=$(curl -s -X GET "${_baseUrl}?name=${_domain_root}&status=active&per_page=1" \
  -H  "X-Auth-Key:${_auth_key}" \
  -H  "X-Auth-Email:${_email}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

# failure : could not detect zone ID .
if [ $(echo $ZONE_ID) = "False" ]; then echo "failure : could not detect zone ID ." >>$_log; exit 1; fi

# get record ID for ACME challenge token ( if specified ) .
RECORD_ID=$(curl -s -X GET "${_baseUrl}/${ZONE_ID}/dns_records?type=TXT&name=_acme-challenge.${_domain}&per_page=1" \
  -H  "X-Auth-Key:${_auth_key}" \
  -H  "X-Auth-Email:${_email}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

# Remove the challenge TXT record from the zone
if [ $(echo $RECORD_ID) = "False" ]; then
  echo "notice : TXT record for ACME challenge token already has gone, ignore it ." >>$_log; exit 0;
elif [ -n "${RECORD_ID}" ]; then
  RECORD_ID=$(curl -s -X DELETE "${_baseUrl}/{ZONE_ID}/dns_records/${RECORD_ID}" \
    -H  "X-Auth-Key:${_auth_key}" \
    -H  "X-Auth-Email:${_email}" \
    -H  "Content-Type: application/json" \
    | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result']['id']) if data['success'] else False;");
  if [ $(echo $ZONE_ID) = "False" ]; then echo "failure : could not remove TXT record for ACME challenge token ." >>$_log; exit 1; fi
fi
