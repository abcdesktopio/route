#!/bin/bash

# create file /tmp/resolver.conf
# Read the nameservers in /etc/resolv.conf
# the create a file for nginx with the content resolver $NAMESERVER_RESOLVER;
if [ -z "$NAMESERVER_RESOLVER" ]; then
  NAMESERVER_RESOLVER=$(grep ^nameserver /etc/resolv.conf | head -n 1 |awk '{ print $2}')
fi
# create nginx resolver directive
echo "resolver $NAMESERVER_RESOLVER;">/tmp/resolver.conf
# dump the file /tmp/resolver.conf
echo NGINX resolver directive dump 
cat /tmp/resolver.conf
# end of create file /tmp/resolver.conf

echo "resolver=$NAMESERVER_RESOLVER"
echo "=== dump vars ==="
export PYOS_FQDN=${PYOS_FQDN:-${PYOS_SERVICE_HOST}}
echo "PYOS_FQDN=$PYOS_FQDN"
echo "PYOS_SERVICE_PORT=$PYOS_SERVICE_PORT"

# start nginx  
exec /usr/local/openresty/nginx/sbin/nginx -p /etc/nginx -c nginx.conf -e /var/log/nginx/error.log
