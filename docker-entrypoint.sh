#!/bin/bash

NAMESERVER_RESOLVER=$(grep ^nameserver /etc/resolv.conf | head -n 1 |awk '{ print $2}')
# create nginx resolver directive
echo "resolver $NAMESERVER_RESOLVER;">/tmp/resolver.conf
# dump /tmp/resolver.conf
echo NGINX resolver directive dump 
cat /tmp/resolver.conf


SPEEDTEST_FQDN=$(nslookup website | awk '/^Name:/ { print $2 }')
PYOS_FQDN=$(nslookup pyos | awk '/^Name:/ { print $2 }')
CONSOLE_FQDN=$(nslookup console | awk '/^Name:/ { print $2 }')
WEBSITE_FQDN=$(nslookup website | awk '/^Name:/ { print $2 }')

export SPEEDTEST_FQDN
export PYOS_FQDN
export CONSOLE_FQDN
export WEBSITE_FQDN

# start nginx web server
# /usr/sbin/nginx
echo "starting nginx web server in foreground" 
/usr/local/openresty/nginx/sbin/nginx -p /etc/nginx -c nginx.conf -e /var/log/nginx/error.log
