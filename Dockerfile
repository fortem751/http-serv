 FROM docker.io/openshift/base-centos7

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN groupadd -r www-data && useradd -r --create-home -g www-data www-data

USER 1001

ENV HTTPD_PREFIX /usr/local/apache2
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "$HTTPD_PREFIX" \
	&& chown 1001:1001 "$HTTPD_PREFIX"
WORKDIR $HTTPD_PREFIX

# install httpd runtime dependencies
# https://httpd.apache.org/docs/2.4/install.html#requirements
RUN yum -y update \
	&& yum install -y \
		gcc \
		openssl-devel \
		apr-devel \
		apr-util-devel \

ENV HTTPD_VERSION 2.4.23
ENV HTTPD_SHA1 5101be34ac4a509b245adb70a56690a84fcc4e7f

# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
ENV HTTPD_BZ2_URL http://mirror.klaus-uwe.me/apache/httpd/httpd-$HTTPD_VERSION.tar.bz2
# not all the mirrors actually carry the .asc files :'(
ENV HTTPD_ASC_URL https://www.apache.org/dist/httpd/httpd-$HTTPD_VERSION.tar.bz2.asc

# see https://httpd.apache.org/docs/2.4/install.html#requirements
RUN set -x \
	&& wget -O httpd.tar.bz2 "$HTTPD_BZ2_URL" \
	&& echo "$HTTPD_SHA1 *httpd.tar.bz2" | sha1sum -c - \
# see https://httpd.apache.org/download.cgi#verify
	&& wget -O httpd.tar.bz2.asc "$HTTPD_ASC_URL" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys A93D62ECC3C8EA12DB220EC934EA76E6791485A8 \
	&& gpg --batch --verify httpd.tar.bz2.asc httpd.tar.bz2 \
	&& rm -r "$GNUPGHOME" httpd.tar.bz2.asc \
	\
	&& mkdir -p src \
	&& tar -xvf httpd.tar.bz2 -C src --strip-components=1 \
	&& rm httpd.tar.bz2 \
	&& cd src \
	\
	&& ./configure \
		--prefix="$HTTPD_PREFIX" \
		--enable-mods-shared=reallyall \
	&& make -j"$(nproc)" \
	&& make install \
	\
	&& cd .. \
	&& rm -r src \
	\
	&& sed -ri \
		-e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
		-e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
		"$HTTPD_PREFIX/conf/httpd.conf" \
	
	

COPY httpd-foreground /usr/local/bin/

EXPOSE 8080 8443
CMD ["httpd-foreground"]