# Using Certbot by EPEL package for SSL connection and auto renewal without HTTP verify (verify ACME token by DNS) .

## TL;DR
1. [Install Certbot](#1-install-certbot).
2. [Getting certificates](#2-getting-certificates).
3. [Variable setting](#3-variable-setting).

## prerequirement
- [ ] All commands need you are "root" or you listed in "wheel" .
- [ ] EPEL repository enabled .
- [ ] PostgreSQL (SSL) enabled .

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
cat << _EOT_ >> /etc/sysconfig/certbot
AUTH_KEY=__
_EOT_
```
