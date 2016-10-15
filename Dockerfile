FROM docker.io/openshift/base-centos7

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added

RUN groupadd -r www-data && useradd -r --create-home -g www-data www-data


#ENV HTTPD_PREFIX /usr/local/apache2
#ENV PATH $HTTPD_PREFIX/bin:$PATH
#RUN mkdir -p "$HTTPD_PREFIX" \
	#&& chown www-data:www-data "$HTTPD_PREFIX"
#WORKDIR $HTTPD_PREFIX

# install httpd runtime dependencies
# https://httpd.apache.org/docs/2.4/install.html#requirements
RUN yum -y update \
	&& yum install -y \
		gcc \
		openssl-devel \
		apr-devel \
		apr-util-devel \

#ENV HTTPD_VERSION 2.4.23
#ENV HTTPD_SHA1 5101be34ac4a509b245adb70a56690a84fcc4e7f


RUN set -x \
	&& yum clean all \
	&& cd /usr/src \
    && curl -sSO http://mirror.klaus-uwe.me/apache/httpd/httpd-${HTTPD_VERSION}.tar.bz2 \
	&& tar xfj httpd-${HTTPD_VERSION}.tar.bz2 \
	&& cd /usr/src/${HTTPD_VERSION}
	&& ./configure --enable-mods-shared=reallyall \
	&& make -j"$(nproc)" \
	&& make install 
	 
	

#COPY httpd-foreground /usr/local/bin/

EXPOSE 8080 8443
USER 1001
CMD ["/usr/local/apache2/bin/httpd -DFOREGROUND]
