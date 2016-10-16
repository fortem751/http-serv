FROM docker.io/openshift/base-centos7


MAINTAINER MBAH Johnas fortem751@gmail.com

EXPOSE 8080 8443
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added

#RUN groupadd -r www-data && useradd -r --create-home -g www-data www-data


#ENV HTTPD_PREFIX /usr/local/apache2
#ENV PATH $HTTPD_PREFIX/bin:$PATH
#RUN mkdir -p "$HTTPD_PREFIX" 
	#&& chown daemon:deamon "$HTTPD_PREFIX"
#WORKDIR $HTTPD_PREFIX

# install httpd runtime dependencies
# https://httpd.apache.org/docs/2.4/install.html#requirements

ENV HTTPD_VERSION 2.4.23

RUN \ 
yum update -y && \
yum install -y gcc && \
yum install -y openssl-devel && \
yum install -y apr-devel && \
yum install -y apr-util-devel && \
yum clean all && \
cd /usr/src && \
curl -O http://mirror.klaus-uwe.me/apache/httpd/httpd-${HTTPD_VERSION}.tar.bz2 && \
tar -xvf httpd-${HTTPD_VERSION}.tar.bz2 && \
cd /usr/src/httpd-${HTTPD_VERSION} && \
./configure --enable-mods-shared=reallyall && \
make && \
make install && \
#sed -ri -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' "${HTTPD_PREFIX}/conf/httpd.conf" && \
sed -ri -e 's/Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf && \
sed -i '/Listen 8080/a Listen 8443' /usr/local/apache2/conf/httpd.conf


#COPY httpd-foreground /usr/local/bin/
RUN chmod -R a+rwx /usr/local/apache2/bin/httpd /usr/local/apache2/logs

#EXPOSE 80
USER 1001
CMD /bin/bash -c 'echo Starting Microservice... ; \
    /usr/local/apache2/bin/httpd -DFOREGROUND || echo Apache start failed: $?'
