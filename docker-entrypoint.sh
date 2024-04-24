#!/bin/bash

NAMESERVER_RESOLVER=$(grep ^nameserver /etc/resolv.conf | head -n 1 |awk '{ print $2}')
# create nginx resolver directive
echo "resolver $NAMESERVER_RESOLVER;">/tmp/resolv.conf
# dump /tmp/resolv.conf
echo NGINX resolver directive dump 
cat /tmp/resolv.conf
echo
# start nginx web server
# /usr/sbin/nginx
echo "starting nginx web server in foreground" 
/usr/local/openresty/nginx/sbin/nginx -p /etc/nginx -c nginx.conf -e /var/log/nginx/error.log
