FROM centos:7

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

RUN yum install -y \
        yum-utils \
        bind-utils \
        net-tools \
        git \
        curl \
        openssl \
        zip \
        unzip \
        bzip2 \
        gettext \
        rsync \
        make \
        gcc \
        g++ \
        nc \
        tcpdump

RUN yum clean all && \
    rm -rf /var/cache/yum/*

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["devel"]