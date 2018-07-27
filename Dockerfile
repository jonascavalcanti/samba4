FROM centos:7.4.1708
LABEL maintainer="unisp <cicero.gadelha@funceme.br | jonas.cavalcantineto@funceme.com>"

RUN yum update -y
RUN yum install epel-release.noarch -y
RUN yum  install -y \
        supervisor wget attr bind-utils docbook-style-xsl gcc gdb krb5-workstation \
        libsemanage-python libxslt perl perl-ExtUtils-MakeMaker \
        perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python \
        python-crypto gnutls-devel libattr-devel keyutils-libs-devel cups-devel \
        libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel \
        pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel \
        libunistring.x86_64 libunistring-devel.x86_64

ENV TZ=America/Fortaleza
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV SAMBA_VERSION="4.8.0"
ENV PATH=/usr/local/samba/bin/:/usr/local/samba/sbin/:$PATH

RUN set -ex \
        && cd /opt \
        && wget --no-check-certificate https://download.samba.org/pub/samba/stable/samba-${SAMBA_VERSION}.tar.gz \
        && tar -zxf samba-${SAMBA_VERSION}.tar.gz \
        && cd /opt/samba-${SAMBA_VERSION}/ \
        && ./configure \ 
        && make \
        && make install

ENV DOMAIN="company.com."
ENV SAMBA_DOMAIN="MYCOMPANY"
ENV SAMBA_REALM="MYCOMPANY.LOCAL"
ENV SAMBA_ADMIN_PASSWORD="12345678"

RUN set -ex \
        && mkdir -p /var/log/samba/ \
        && touch /var/log/samba/samba.log

COPY confs/supervisord.conf /etc/supervisord.conf
COPY confs/smb.conf /tmp/smb.conf
COPY confs/krb5.conf /tmp/krb5.conf

COPY confs/init_samab4_conf.sh /init_samab4_conf.sh
RUN chmod +x /init_samab4_conf.sh

COPY confs/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 53/tcp 53/udp 88/tcp 88/udp 135/tcp 137/udp 138/udp 139/tcp 389/tcp 389/udp 445/tcp 464/tcp 464/udp 636/tcp
 
WORKDIR /usr/local/samba/

CMD ["/start.sh"]