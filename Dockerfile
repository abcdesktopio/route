# Default release is jammy
ARG BASE_IMAGE_RELEASE=jammy
# Default base image 
ARG BASE_IMAGE=abcdesktopio/openresty

# --- START Build image ---
FROM $BASE_IMAGE:$BASE_IMAGE_RELEASE

RUN apt-get update && \
    apt-get install -y --no-install-recommends dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install lua libs
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-string && \
    /usr/local/openresty/luajit/bin/luarocks install lua-cjson && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-rsa && \
    /usr/local/openresty/luajit/bin/luarocks install lua-resty-dns

# create default directory /var/log/nginx 
RUN mkdir -p /var/log/nginx

# copy all nginx configuration files
COPY etc/nginx /etc/nginx
COPY docker-entrypoint.sh /
EXPOSE 80 443
CMD ["/docker-entrypoint.sh"]
