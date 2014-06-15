FROM ubuntu:14.04
MAINTAINER Sergio Castano Arteaga "sergio.castano.arteaga@gmail.com"

# Nginx version
ENV NGINX_VERSION 1.4.7

# Your Forgerock account details
# https://backstage.forgerock.com/#/account/register
ENV FORGEROCK_USERNAME your_username_here
ENV FORGEROCK_PASSWORD your_password_here

# Update package index and install some packages we'll need
RUN apt-get update && \
    apt-get -y install unzip \
        wget \
        git \
        subversion \
        build-essential \
        ant \
        openjdk-7-jdk \
        zlib1g-dev \
        libnspr4-dev \
        libnss3-dev \
        python-dev

# Checkout OpenAM webagents from incubator branch
RUN cd /tmp && \
    svn co \
        --trust-server-cert \
        --username $FORGEROCK_USERNAME \
        --password $FORGEROCK_PASSWORD \
        https://svn.forgerock.org/openam/branches/incubator/opensso/

# Install libxml2
RUN cd /tmp && \
    wget ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz && \
    tar xvfz libxml2-2.9.1.tar.gz && \
    rm -f libxml2-2.9.1.tar.gz && \
    mv libxml2-2.9.1 libxml2 && \
    cd libxml2 && \
    ./configure && \
    make && \
    mv .libs lib

# Install libpcre
RUN cd /tmp && \
    wget http://downloads.sourceforge.net/project/pcre/pcre/8.35/pcre-8.35.tar.gz && \
    tar xvfz pcre-8.35.tar.gz && \
    rm -f pcre-8.35.tar.gz && \
    mv pcre-8.35 pcre && \
    cd pcre && \
    export CFLAGS="-g -fPIC" && \
    ./configure && \
    make && \
    mv .libs lib

# Symlink make to gmake
RUN ln -s /usr/bin/make /usr/bin/gmake

# Update paths in webagents Makefile
RUN sed -i "/libxml2/c\CFLAGS += -I/tmp/libxml2/include -I/tmp/pcre" \
    /tmp/opensso/products/webagents/Makefile
RUN sed -i "/libpcre.a/c\EXT_LIBS = /tmp/pcre/lib/libpcre.a" \
    /tmp/opensso/products/webagents/Makefile
RUN sed -i "/LDFLAGS/c\ LDFLAGS = -L\/tmp\/libxml2\/lib" \
    /tmp/opensso/products/webagents/Makefile

# Update Nginx version to use
RUN sed -i "/NGINX_VER=/c\NGINX_VER=$NGINX_VERSION" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile

# Update paths in nginx agent Makefile
RUN sed -i "/PCRE_DIR=/c\PCRE_DIR=/tmp/pcre" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile
RUN sed -i "/CFLAGS=/c\CFLAGS=-g -I..\/..\/..\/am\/source\/ -I\$(PCRE_DIR) -I\$(OPENSSL_DIR)\/include" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile

# Update paths in nginx agent config file
RUN sed -i "/XML2_LIB=/c\XML2_LIB=/tmp/libxml2/lib" \
    /tmp/opensso/products/webagents/agents/source/nginx/config
RUN sed -i "/lnssutil3/ s/lnssutil3/lnssutil3 -lm -lrt/" \
    /tmp/opensso/products/webagents/agents/source/nginx/config

# Update OpenSSL version to 1.0.1h in nginx agent Makefile
# More info: https://github.com/openssl/openssl/commit/23f5908
RUN sed -i "/OPENSSL_VER=1.0.1g/c\OPENSSL_VER=1.0.1h" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile

# Disable warnings as errors when compiling nginx
RUN sed -i "/touch build/a\\\tsed -i \"/Werror/d\" build/auto/cc/gcc" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile        

## --- EXTRA NGINX MODULES TO ADD --- 

# Fetch redis2 nginx module source and add its path to the Makefile 
# to include it in the nginx build
RUN cd /tmp && \
    git clone https://github.com/openresty/redis2-nginx-module
RUN sed -i "/with-openssl/i\\\t\\t--add-module=\/tmp\/redis2-nginx-module \\\\" \
    /tmp/opensso/products/webagents/agents/source/nginx/Makefile

# Feel free to add here as many extra modules as you want

## --- END EXTRA NGINX MODULES TO ADD ---

# Build nginx (with openam modules + all we have just added)
RUN cd /tmp/opensso/products/webagents && ant nginx -Dbuild.type=64

# Check that everything went ok listing nginx compilation flags
RUN cd /lib/x86_64-linux-gnu/ && \
    ln -s libpcre.so.3 libpcre.so.1 && \
    /tmp/opensso/products/webagents/built/nginx/scratch/web_agents/nginx_agent/bin/nginx -V


CMD ["cat", "/tmp/opensso/products/webagents/built/dist/nginx_Linux_64_agent_4.0.0-SNAPSHOT.zip"]

