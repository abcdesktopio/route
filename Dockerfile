# Default release is jammy
ARG BASE_IMAGE_RELEASE=jammy
# Default base image 
ARG BASE_IMAGE=openresty/openresty

# --- START Build image ---
FROM $BASE_IMAGE:$BASE_IMAGE_RELEASE

# install lua libs
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-string && \
    /usr/local/openresty/luajit/bin/luarocks install lua-cjson && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-rsa

# create default directory /var/log/nginx 
RUN mkdir -p /var/log/nginx

# copy all nginx configuration files
COPY etc/nginx /etc/nginx

EXPOSE 80 443
CMD ["/docker-entrypoint.sh"]
