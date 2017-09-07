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
# - AUTH_KEY : Cloudflare API param: "X-Auth-Key"
# - EMAIL : Cloudflare API param: "X-Auth-Email"
# important : You should write those in /etc/sysconfig/certbot .
#
# see more information : "DNS Records for a Zone" section at https://api.cloudflare.com/ .

###
# statics
declare -r baseUrl=https://api.cloudflare.com/client/v4/zones
declare -r logDir=/var/log/letsencrypt
declare -r tempDir=/tmp/CERTBOT_$CERTBOT_DOMAIN
declare -r datetime=`date +"%Y%m%d%H%M%S"`

if [ -f $tempDir/ZONE_ID ]; then
  ZONE_ID=$(cat $tempDir/ZONE_ID)
  rm -f $tempDir/ZONE_ID
fi

if [ -f $tempDir/RECORD_ID ]; then
  RECORD_ID=$(cat $tempDir/RECORD_ID)
  rm -f $tempDir/RECORD_ID
fi

# Remove the challenge TXT record from the zone
if [ -n "${ZONE_ID}" ]; then
  if [ -n "${RECORD_ID}" ]; then
    RECORD_ID=$(curl -s -X DELETE "${baseUrl}?/zones/{ZONE_ID}/dns_records/${RECORD_ID}" \
    -H  "X-Auth-Key:${AUTH_KEY}" \
    -H  "X-Auth-Email:${EMAIL}" \
    -H  "Content-Type: application/json" \
    | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result']['id']) if data['success'] else False;")

#    if [ $(echo $ZONE_ID) = "False" ]; then echo "failure : could not remove TXT record for ACME challenge token ."; exit 1; fi

  fi
fi
