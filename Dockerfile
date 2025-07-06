# Default release is jammy
ARG BASE_IMAGE_RELEASE=jammy
# Default base image 
ARG BASE_IMAGE=openresty/openresty

# --- START Build image ---
FROM $BASE_IMAGE:$BASE_IMAGE_RELEASE

# install lua libs
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-string 
RUN /usr/local/openresty/luajit/bin/luarocks install lua-cjson
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-rsa
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-dns

# copy all nginx configuration files
COPY etc/nginx /etc/nginx

# create default directory /var/log/nginx 
RUN mkdir -p /etc/nginx/logs /var/log/nginx /var/lib/nginx/html/.well-known/acme-challenge

COPY docker-entrypoint.sh /
EXPOSE 80 443
CMD ["/docker-entrypoint.sh"]
