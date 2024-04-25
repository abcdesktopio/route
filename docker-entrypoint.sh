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

while true; do
  if [ -z "$SPEEDTEST_FQDN" ]; then
    SPEEDTEST_FQDN=$(nslookup website | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$PYOS_FQDN" ]; then
    PYOS_FQDN=$(nslookup pyos | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$CONSOLE_FQDN" ]; then
    CONSOLE_FQDN=$(nslookup console | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$WEBSITE_FQDN" ]; then
    WEBSITE_FQDN=$(nslookup website | awk '/^Name:/ { print $2 }')
  fi
  
  if [ -z "$SPEEDTEST_FQDN" ] || [ -z "$PYOS_FQDN" ] || [ -z "$CONSOLE_FQDN" ] || [ -z "$WEBSITE_FQDN" ] ; then
    echo "SPEEDTEST_FQDN=$SPEEDTEST_FQDN"
    echo "PYOS_FQDN=$PYOS_FQDN"
    echo "CONSOLE_FQDN=$CONSOLE_FQDN"
    echo "WEBSITE_FQDN=$WEBSITE_FQDN" 
    echo "sleeping for 1s, for nslookup"
    sleep 1s
  else
    break
  fi
done

echo 
echo "=========================="
echo "nginx is starting with env"
echo "resolver=$NAMESERVER_RESOLVER"
echo "SPEEDTEST_FQDN=$SPEEDTEST_FQDN"
echo "PYOS_FQDN=$PYOS_FQDN"
echo "CONSOLE_FQDN=$CONSOLE_FQDN"
echo "WEBSITE_FQDN=$WEBSITE_FQDN"

export SPEEDTEST_FQDN
export PYOS_FQDN
export CONSOLE_FQDN
export WEBSITE_FQDN

# start nginx web server
# /usr/sbin/nginx
echo "starting nginx web server in foreground" 
/usr/local/openresty/nginx/sbin/nginx -p /etc/nginx -c nginx.conf -e /var/log/nginx/error.log
