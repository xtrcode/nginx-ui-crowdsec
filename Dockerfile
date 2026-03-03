FROM docker.io/uozi/nginx-ui:latest AS builder

RUN apt-get update && apt-get install -y \
    wget git build-essential \
    libpcre2-dev zlib1g-dev libssl-dev \
    libluajit-5.1-dev luajit

RUN NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9\.]*') && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar -zxf nginx-$NGINX_VERSION.tar.gz && \
    git clone https://github.com/vision5/ngx_devel_kit.git && \
    git clone https://github.com/openresty/lua-nginx-module.git && \
    cd nginx-$NGINX_VERSION && \
    export LUAJIT_LIB=/usr/lib/$(uname -m)-linux-gnu && \
    export LUAJIT_INC=/usr/include/luajit-2.1 && \
    ./configure --with-compat \
    --add-dynamic-module=../ngx_devel_kit \
    --add-dynamic-module=../lua-nginx-module && \
    make modules

FROM docker.io/uozi/nginx-ui:latest

RUN apt-get update && apt-get install -y \
    luajit libluajit-5.1-dev luarocks gettext-base curl gnupg && \
    rm -rf /var/lib/apt/lists/*


COPY --from=builder /nginx-*/objs/ndk_http_module.so /etc/nginx/modules/
COPY --from=builder /nginx-*/objs/ngx_http_lua_module.so /etc/nginx/modules/

RUN curl -sL https://github.com/crowdsecurity/cs-nginx-bouncer/releases/latest/download/crowdsec-nginx-bouncer.tgz \
    | tar -xz && \
    cd crowdsec-nginx-bouncer-v* && \
    sed -i 's/sudo//g' install.sh && \
    ./install.sh