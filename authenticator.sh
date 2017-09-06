#!/bin/bash
set -ue -o pipefail
export LC_ALL=C
###
# authenticator.sh
# https://github.com/furplag/certbot-dns
# Copyright 2017 furplag
# Licensed under Apache 2.0 (https://github.com/furplag/certbot-dns/blob/master/LICENSE)

# You must specify these variables in /etc/sysconfig/certbot.
# - CF_AUTH_KEY : Cloudflare API param: "X-Auth-Key"
# - CF_AUTH_EMAIL : Cloudflare API param: "X-Auth-Email"

# Optional variables
declare -r BASE_URL=https://api.cloudflare.com/client/v4/zones
CERTBOT_DOMAIN=${CERTBOT_DOMAIN:-NOPE}
CERTBOT_VALIDATION=${CERTBOT_VALIDATION:-NOPE}

# Strip only the top domain to get the zone id
DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')

ZONE_ID=$(curl -s -X GET "${BASE_URL}?name=${DOMAIN}&status=active&per_page=1" \
  -H  "X-Auth-Key:${CF_AUTH_KEY:-N/A}" \
  -H  "X-Auth-Email:${CF_AUTH_EMAIL:-${EMAIL}}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

if [ $(echo $ZONE_ID) = "False" ]; then exit 1; fi

RECORD_ID=$(curl -s -X GET "${BASE_URL}/${ZONE_ID}/dns_records?type=TXT&name=_acme-challenge.${$CERTBOT_DOMAIN}&per_page=1" \
  -H  "X-Auth-Key:${CF_AUTH_KEY:-N/A}" \
  -H  "X-Auth-Email:${CF_AUTH_EMAIL:-N/A}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

if [ $(echo $RECORD_ID) = "False" ]; then
  RECORD_ID=$(curl -s -X POST "${BASE_URL}/${ZONE_ID}/dns_records" \
  -H  "X-Auth-Key:${CF_AUTH_KEY:-N/A}" \
  -H  "X-Auth-Email:${CF_AUTH_EMAIL:-N/A}" \
  -H  "Content-Type: application/json" \
  --data '{"type":"TXT","name":"'"_acme-challenge.${$CERTBOT_DOMAIN}"'","content":"'"$CERTBOT_VALIDATION"'"}' \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")
else
  RECORD_ID=$(curl -s -X POST "${BASE_URL}/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H  "X-Auth-Key:${CF_AUTH_KEY:-N/A}" \
  -H  "X-Auth-Email:${CF_AUTH_EMAIL:-N/A}" \
  -H  "Content-Type: application/json" \
  --data '{"type":"TXT","name":"'"_acme-challenge.${$CERTBOT_DOMAIN}"'","content":"'"$CERTBOT_VALIDATION"'"}' \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")
fi

if [ $(echo $RECORD_ID) = "False" ]; then exit 1; fi

if [ ! -d /tmp/CERTBOT_$CERTBOT_DOMAIN ];then
  mkdir -m 0700 /tmp/CERTBOT_$CERTBOT_DOMAIN
fi

echo $ZONE_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID
echo $RECORD_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
