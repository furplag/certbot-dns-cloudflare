# Using Certbot by EPEL package for SSL connection and auto renewal without HTTP verify (verify ACME token by DNS) .

## TL;DR
1. [Install Certbot](#1-install-certbot).
2. [Getting certificates](#2-getting-certificates).
3. [Variable setting](#3-variable-setting).
4. [Register Service and Timer](#4-register-service-and-timer).
5. [Activate](#5-activate).

## prerequirement
- [ ] All commands need you are "root" or you listed in "wheel" .
- [ ] EPEL repository enabled .

____

### 1. Install Certbot

```bash
# yum install -y certbot
```

### 2. Getting certificates

```bash
# certbot certonly --preferred-challenges dns-01 --authenticator manual --domain _type.your.domain.here_
```

### 3. Variable setting

```bash
sed -i -e 's/^CERTBOT_ARGS=/#\0/' /etc/sysconfig/certbot
sed -i -e 's/^PRE_HOOK=/#\0/' /etc/sysconfig/certbot
sed -i -e 's/^RENEW_HOOK=/#\0/' /etc/sysconfig/certbot
sed -i -e 's/^POST_HOOK=/#\0/' /etc/sysconfig/certbot

cat << _EOT_ >> /etc/sysconfig/certbot

CLOUDFLARE_AUTH_KEY=_cloudflare.api.key.of.your.site_
CLOUDFLARE_AUTH_EMAIL=_email.address.associated.with.your.cloudflare.account_
CERTBOT_ARGS="--manual --preferred-challenges=dns --manual-auth-hook _/path/to/certbot-dns-cloudflare/_authenticator.sh --manual-cleanup-hook _/path/to/certbot-dns-cloudflare/_cleanup.sh -d _your.domain.here_ --agree-tos --keep-until-expiring --manual-public-ip-logging-ok"

PRE_HOOK=""
RENEW_HOOK=""
# add post Hook
# e.g. restart httpd after renewal, put variable : POST_HOOK="--post-hook 'systemctl restart httpd'".
POST_HOOK="--post-hook 'systemctl restart httpd'"

# e.g. overwrite PostgreSQL tls, put variable : POST_HOOK="--post-hook '_/path/to/certbot-dns-cloudflare/_postgresql.sh'".
#POST_HOOK="--post-hook '_/path/to/certbot-dns-cloudflare/_postgresql.sh'
#PGDATA=_/path/to/postgres/x.x/_/data
#PG_SERVICE=_service.name.of.postgresql-x.x_

_EOT_

```

### 4. Register Service and Timer

```bash
cat << _EOT_ >> /usr/lib/systemd/system/certbot-certonly.service
[Unit]
Description=This service automatically renews any certbot certificates found

[Service]
EnvironmentFile=/etc/sysconfig/certbot
Type=oneshot
ExecStart=/usr/bin/certbot certonly \$PRE_HOOK \$POST_HOOK \$RENEW_HOOK \$CERTBOT_ARGS

_EOT_

cat << _EOT_ >> /usr/lib/systemd/system/certbot-certonly.timer
[Unit]
Description=This is the timer to set the schedule for automated renewals

[Timer]
OnCalendar=daily
RandomizedDelaySec=6hours
Persistent=true

[Install]
WantedBy=timers.target

_EOT_
```

### 5. Activate
```bash
systemctl enable certbot-certonly.service && \
systemctl start certbot-certonly.timer && \
systemctl enable certbot-certonly.timer
```
