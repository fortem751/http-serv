FROM registry.access.redhat.com/rhel7:latest

ENV TZ=Europe/Vienna \
    VERSION_HTTPD=2.4.23 \
    VERSION_APR=1.5.2 \
	VERSION_APR_UTIL=1.5.4

# TODO: Add sha1 check summs
#  /usr/local/apache2

RUN set -x \
  && BUILD_DEPS="pcre-devel openssl-devel bzip2-devel zlib-devel libuuid-devel" \
  && yum clean all \
  && yum-config-manager --enable rhel-7-server-optional-rpms \
  && yum -y update \
  && yum -y --skip-broken install socat tar nss_wrapper libuuid  \
  && yum -y --skip-broken groupinstall 'Development Tools' --setopt=group_package_types=mandatory,default,optional \
  && yum -y --skip-broken install $BUILD_DEPS \
  && echo "/usr/local/apr/lib" > /etc/ld.so.conf.d/apr.conf \
  && cd /usr/src \
  && curl -sSO http://mirror.klaus-uwe.me/apache/httpd/httpd-${VERSION_HTTPD}.tar.bz2 \
  && curl -sSO http://mirror.klaus-uwe.me/apache//apr/apr-${VERSION_APR}.tar.bz2 \
  && curl -sSO http://mirror.klaus-uwe.me/apache//apr/apr-util-${VERSION_APR_UTIL}.tar.bz2 \
  && tar xfj httpd-${VERSION_HTTPD}.tar.bz2 \
  && tar xfj apr-${VERSION_APR}.tar.bz2 \
  && tar xfj apr-util-${VERSION_APR_UTIL}.tar.bz2 \
  && cd apr-${VERSION_APR} \
  && ./configure --enable-nonportable-atomics=yes \
  && make \
  && make install \
  && ldconfig \
  && cd ../apr-util-${VERSION_APR_UTIL} \
  && ./configure --with-apr=/usr/local/apr --with-crypto \
  && make \
  && make install \
  && ldconfig \
  && cd ../httpd-${VERSION_HTTPD} \
  && ./configure --enable-mpms-shared=all --enable-proxy --enable-proxy-fcgi --enable-proxy-balancer --enable-lbmethod-byrequests \
             --enable-lbmethod-bytraffic --enable-lbmethod-bybusyness --enable-lbmethod-heartbeat --enable-deflate --enable-http \
			 --enable-logio --enable-expires --enable-remoteip --enable-proxy-http --enable-proxy-hcheck --enable-watchdog \
			 --enable-ssl \
  && make \
  && make install \
  && cd .. \
  && rm -rf httpd-${VERSION_HTTPD}* apr-${VERSION_APR}* apr-util-${VERSION_APR_UTIL}* \
  && /usr/local/apache2/bin/httpd -S \
  && /usr/local/apache2/bin/httpd -l \
  && /usr/local/apache2/bin/httpd -t -D DUMP_MODULES
  
EXPOSE 8080 8443

USER 1001
