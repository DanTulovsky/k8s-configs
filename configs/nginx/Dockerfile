# https://github.com/bitnami/bitnami-docker-nginx

ARG NGINX_VERSION=1.19.6
ARG BITNAMI_NGINX_REVISION=r44
ARG BITNAMI_NGINX_TAG=${NGINX_VERSION}-debian-10-${BITNAMI_NGINX_REVISION}

FROM bitnami/nginx:${BITNAMI_NGINX_TAG} AS builder
USER root
# upstream image sets this to "/" which breaks jaeger compile
ENV HOME="/root"

ARG OPENTRACING_CPP_VERSION=v1.6.0
ARG ZIPKIN_CPP_VERSION=v0.5.2
ARG LIGHTSTEP_VERSION=v0.14.0
ARG JAEGER_CPP_VERSION=v0.6.0
ARG GRPC_VERSION=v1.34.1
ARG DATADOG_VERSION=v1.2.0

# Redeclare NGINX_VERSION so it can be used as a parameter inside this build stage
ARG NGINX_VERSION

# Install required packages and build dependencies
RUN install_packages dirmngr gpg gpg-agent \
    # RUN apt update
    # RUN apt install -y dirmngr gpg gpg-agent \
    curl build-essential libpcre3-dev \
    zlib1g-dev libperl-dev libcurl4-openssl-dev \
    libprotobuf-dev protobuf-compiler build-essential \
    cmake git ca-certificates pkg-config \
    wget libz-dev automake autogen autoconf libtool g++ \
    protobuf-compiler-grpc libgrpc++-dev libgrpc-dev libyaml-cpp0.6

RUN tempDir="$(mktemp -d)" && chmod 777 "$tempDir"

# Add trusted NGINX PGP key for tarball integrity verification
# RUN gpg --keyserver pgp.mit.edu --recv-key 520A9993A1C052F8

RUN git clone https://github.com/opentracing-contrib/nginx-opentracing.git

### Build opentracing-cpp
RUN git clone -b $OPENTRACING_CPP_VERSION https://github.com/opentracing/opentracing-cpp.git
RUN cd opentracing-cpp \
    && mkdir .build && cd .build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. \
    && make && make install \
    && cd "$tempDir"

### Build zipkin-cpp-opentracing
# RUN git clone -b $ZIPKIN_CPP_VERSION https://github.com/rnburn/zipkin-cpp-opentracing.git
# RUN cd zipkin-cpp-opentracing \
#     && mkdir .build && cd .build \
#     && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. \
#     && make && make install \
#     && cd "$tempDir" \
#     && ln -s /usr/local/lib/libzipkin_opentracing.so /usr/local/lib/libzipkin_opentracing_plugin.so

### Build lightstep-tracer-cpp
# RUN git clone -b $LIGHTSTEP_VERSION https://github.com/lightstep/lightstep-tracer-cpp.git \
#     && cd lightstep-tracer-cpp \
#     && mkdir .build && cd .build \
#     && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. \
#     && make && make install \
#     && cd "$tempDir" \
#     && ln -s /usr/local/lib/liblightstep_tracer.so /usr/local/lib/liblightstep_tracer_plugin.so

### Build Jaeger cpp-client
RUN git clone -b $JAEGER_CPP_VERSION https://github.com/jaegertracing/cpp-client.git jaeger-cpp-client
RUN cd jaeger-cpp-client \
    && mkdir .build && cd .build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DJAEGERTRACING_WITH_YAML_CPP=ON .. \
    && make && make install \
    && export HUNTER_INSTALL_DIR=$(cat _3rdParty/Hunter/install-root-dir) \
    && cd "$tempDir" \
    && ln -s /usr/local/lib/libjaegertracing.so /usr/local/lib/libjaegertracing_plugin.so

# Download NGINX, verify integrity and extract
RUN cd /tmp && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc && \
    # gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz

# Compile NGINX with desired module
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    rm -rf /opt/bitnami/nginx && \
    ./configure --prefix=/opt/bitnami/nginx \
    --with-compat \
    --add-dynamic-module=/app/nginx-opentracing/opentracing \
    --with-cc-opt="-I$HUNTER_INSTALL_DIR/include" \
    --with-ld-opt="-L$HUNTER_INSTALL_DIR/lib" \
    && make \
    && make install


FROM bitnami/nginx:${BITNAMI_NGINX_TAG}
USER root

# Install module deps
RUN install_packages protobuf-compiler-grpc iputils-ping curl protobuf-compiler libgrpc6 libyaml-cpp0.6

RUN mkdir -p /usr/local/lib/
RUN chmod -R a+rx /usr/local/

# Install module files
COPY --from=builder /opt/bitnami/nginx/modules/ngx_http_opentracing_module.so /opt/bitnami/nginx/modules/ngx_http_opentracing_module.so
COPY --from=builder /usr/local/lib/libopentracing.so.1.6.0 /usr/local/lib/libopentracing.so.1.6.0
RUN ln -s /usr/local/lib/libopentracing.so.1.6.0 /usr/lib/libopentracing.so.1
RUN ln -s /usr/local/lib/libopentracing.so.1.6.0 /usr/lib/libopentracing.so
COPY --from=builder /usr/local/lib/libjaegertracing.so.0.6.0 /usr/local/lib/libjaegertracing.so.0.6.0
RUN ln -s /usr/local/lib/libjaegertracing.so.0.6.0 /usr/local/lib/libjaegertracing_plugin.so

# Enable module
# We don't use this, entire nginx.conf is in configMap
RUN echo "load_module modules/ngx_http_opentracing_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
    cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf

# Set the container to be run as a non-root user by default
USER 1001
