FROM debian:10-slim

WORKDIR /root

RUN echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backports.list

RUN apt-get update -qq && \
    apt-get install -y apt-transport-https \
                       ca-certificates \
                       software-properties-common \
                       httping \
                       man \
                       man-db \
                       vim \
                       screen \
                       curl \
                       gnupg \
                       atop \
                       htop \
                       dstat \
                       jq \
                       dnsutils \
                       tcpdump \
                       traceroute \
                       iputils-ping \
                       net-tools \
                       netcat \
                       iproute2 \
                       strace \
                       telnet \
                       openssl \
                       psmisc \
                       dsniff \
                       conntrack

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["devel"]