#!/bin/bash

if [ -z "$NAMESERVER_RESOLVER" ]; then
  NAMESERVER_RESOLVER=$(grep ^nameserver /etc/resolv.conf | head -n 1 |awk '{ print $2}')
fi

# create nginx resolver directive
echo "resolver $NAMESERVER_RESOLVER;">/tmp/resolver.conf
# dump /tmp/resolver.conf
echo NGINX resolver directive dump 
cat /tmp/resolver.conf
echo "resolver=$NAMESERVER_RESOLVER"
echo "=== dump vars ==="
export PYOS_FQDN=${PYOS_FQDN:-${PYOS_SERVICE_HOST}}
echo "PYOS_FQDN=$PYOS_FQDN"
echo "PYOS_SERVICE_PORT=$PYOS_SERVICE_PORT"
# export 
exec /usr/local/openresty/nginx/sbin/nginx -p /etc/nginx -c nginx.conf -e /var/log/nginx/error.log
