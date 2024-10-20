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

#
# root@router-od-68cf7d99b-xflnt:/etc/nginx/sites-enabled# env |grep HOST
# MEMCACHED_SERVICE_HOST=10.98.38.64
# HOSTNAME=router-od-68cf7d99b-xflnt
# SPEEDTEST_SERVICE_HOST=10.103.135.215
# PYOS_SERVICE_HOST=10.110.142.119
# OPENLDAP_SERVICE_HOST=10.99.183.131
# MONGODB_SERVICE_HOST=10.102.192.143
# KUBERNETES_SERVICE_HOST=10.96.0.1
# HTTP_ROUTER_SERVICE_HOST=10.103.230.142
# WEBSITE_SERVICE_HOST=10.104.176.157
# CONSOLE_SERVICE_HOST=10.111.71.209
#

while true; do
  if [ -z "$SPEEDTEST_FQDN" ]; then
    # read the FQDN
    # by default speedtest.abcdesktop.svc.cluster.local but can change by custom kubernetes cluster config
    SPEEDTEST_FQDN=$(nslookup speedtest | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$PYOS_FQDN" ]; then
    # read the FQDN
    # by default pyos.abcdesktop.svc.cluster.local but can change by custom kubernetes cluster config
    PYOS_FQDN=$(nslookup pyos | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$CONSOLE_FQDN" ]; then
    # read the FQDN
    # by default console.abcdesktop.svc.cluster.local but can change by custom kubernetes cluster config
    CONSOLE_FQDN=$(nslookup console | awk '/^Name:/ { print $2 }')
  fi

  if [ -z "$WEBSITE_FQDN" ]; then
    # read the FQDN
    # by default website.abcdesktop.svc.cluster.local but can change by custom kubernetes cluster config
    WEBSITE_FQDN=$(nslookup website | awk '/^Name:/ { print $2 }')
  fi
  
  if [ -z "$SPEEDTEST_FQDN" ] || [ -z "$PYOS_FQDN" ] || [ -z "$CONSOLE_FQDN" ] || [ -z "$WEBSITE_FQDN" ] ; then
    echo "SPEEDTEST_FQDN=$SPEEDTEST_FQDN"
    echo "PYOS_FQDN=$PYOS_FQDN"
    echo "CONSOLE_FQDN=$CONSOLE_FQDN"
    echo "WEBSITE_FQDN=$WEBSITE_FQDN" 
    echo "sleeping for 1s, for dns resolv"
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
