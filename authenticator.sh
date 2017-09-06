#!/bin/bash
set -ue -o pipefail
export LC_ALL=C
###
# authenticator.sh
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
declare -r BASE_URL=https://api.cloudflare.com/client/v4/zones
declare -r DOMAIN=$(expr match "${CERTBOT_DOMAIN}" '.*\.\(.*\..*\)')

# get zone ID .
ZONE_ID=$(curl -s -X GET "${BASE_URL}?name=${DOMAIN}&status=active&per_page=1" \
  -H  "X-Auth-Key:${AUTH_KEY}" \
  -H  "X-Auth-Email:${EMAIL}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

# failure : could not detect zone ID .
if [ $(echo $ZONE_ID) = "False" ]; then echo "failure : could not detect zone ID ."; exit 1; fi

# get record ID for ACME challenge token ( if specified ) .
RECORD_ID=$(curl -s -X GET "${BASE_URL}/${ZONE_ID}/dns_records?type=TXT&name=_acme-challenge.${CERTBOT_DOMAIN}&per_page=1" \
  -H  "X-Auth-Key:${AUTH_KEY}" \
  -H  "X-Auth-Email:${EMAIL}" \
  -H  "Content-Type: application/json" \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result'][0]['id']) if data['success'] and data['result_info']['count'] > 0 else False;")

if [ $(echo $RECORD_ID) = "False" ]; then
  # create TXT record for ACME challenge token .
  RECORD_ID=$(curl -s -X POST "${BASE_URL}/${ZONE_ID}/dns_records" \
  -H  "X-Auth-Key:${AUTH_KEY}" \
  -H  "X-Auth-Email:${EMAIL}" \
  -H  "Content-Type: application/json" \
  --data '{"type":"TXT","name":"'"_acme-challenge.${CERTBOT_DOMAIN}"'","content":"'"${CERTBOT_VALIDATION}"'"}' \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result']['id']) if data['success'] else False;")
else
  # update TXT record for ACME challenge token .
  RECORD_ID=$(curl -s -X PUT "${BASE_URL}/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H  "X-Auth-Key:${AUTH_KEY}" \
  -H  "X-Auth-Email:${EMAIL}" \
  -H  "Content-Type: application/json" \
  --data '{"type":"TXT","name":"'"_acme-challenge.${CERTBOT_DOMAIN}"'","content":"'"${CERTBOT_VALIDATION}"'"}' \
  | python -c "import sys;import json;data=json.load(sys.stdin);print(data['result']['id']) if data['success'] else False;")
fi

# failure : could not specify TXT record for ACME challenge token .
if [ $(echo $RECORD_ID) = "False" ]; then echo "failure : could not specify TXT record for ACME challenge token ."; exit 1; fi

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
