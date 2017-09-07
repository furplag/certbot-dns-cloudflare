#!/bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# postgres.sh
# 
# https://github.com/furplag/certbot-dns
# Copyright 2017 furplag
# Licensed under Apache 2.0 (https://github.com/furplag/certbot-dns/blob/master/LICENSE)

###
# variables
# - PG_DATA : path to postgresql data directory .
# - PG_SERVICE : the name of postgresql service .
# important : You should write those in /etc/sysconfig/certbot .

if [ ! -z "${PG_DATA}" ]; then exit 0; fi
if [ ! -z "${PG_SERVICE}" ]; then exit 0; fi
if [ ! -z "${CERTBOT_DOMAIN}" ]; then echo "undefined: CERTBOT_DOMAIN ."; exit 0; fi

if [ -f "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem" ]; then
  rm -rf ${PG_DATA}/privkey.pem && \
  cp -p "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem" "${PG_DATA}/." && \
  chown postgres:postgres ${PG_DATA}/privkey.pem && \
  chmod 0600 ${PG_DATA}/privkey.pem;
fi
if [ -f "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" ]; then
  rm -rf ${PG_DATA}/fullchain.pem && \
  cp -p "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" "${PG_DATA}/." && \
  chown postgres:postgres ${PG_DATA}/fullchain.pem && \
  chmod 0600 ${PG_DATA}/fullchain.pem;
fi

/usr/bin/systemctl restart postgresql-9.6.service
