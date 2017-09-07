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
# - PGDATA : path to postgresql data directory .
# - PG_SERVICE : the name of postgresql service .
# important : You should write those in /etc/sysconfig/certbot .

if [ -z "${PGDATA}" ]; then echo "undefined: PG_DATA ."; exit 0; fi
if [ -z "${PG_SERVICE}" ]; then echo "undefined: PG_SERVICE ."; exit 0; fi
if [ -z "${CERTBOT_DOMAIN}" ]; then echo "undefined: CERTBOT_DOMAIN ."; exit 0; fi

if [ -f "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem" ]; then
  rm -rf ${PGDATA}/privkey.pem
  cp -p "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem" "${PGDATA}/." && \
  chown postgres:postgres ${PGDATA}/privkey.pem && \
  chmod 0600 ${PGDATA}/privkey.pem
fi

if [ -f "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" ]; then
  rm -rf ${PGDATA}/fullchain.pem
  cp -p "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" "${PGDATA}/." && \
  chown postgres:postgres ${PGDATA}/fullchain.pem && \
  chmod 0600 ${PGDATA}/fullchain.pem
fi

/usr/bin/systemctl restart "${PG_SERVICE}.service"
