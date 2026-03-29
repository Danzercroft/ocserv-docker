FROM alpine:3.23.3

# OCServ Docker Image - собран из исходного кода на Alpine Linux
# Версия ocserv: 1.4.1 (релизная)
# Базовый образ: Alpine Linux 3.23.3
# Все возможности включены: PAM, RADIUS, GSSAPI

# Установка зависимостей для сборки ocserv
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    curl \
    git \
    gnutls-dev \
    gperf \
    ipcalc \
    krb5-dev \
    libev-dev \
    libnl3-dev \
    libtool \
    linux-headers \
    linux-pam-dev \
    meson \
    musl-dev \
    ninja \
    pkgconfig \
    protobuf-c-dev \
    readline-dev \
    talloc-dev \
    wget
    
RUN apk add --no-cache \
    gettext \
    gnutls \
    gnutls-utils \
    iptables \
    krb5 \
    libev \
    libnl3 \
    linux-pam \
    protobuf-c \
    readline \
    talloc \
    socat \
    rsyslog

# Версия ocserv для сборки
ENV OCSERV_VERSION=1.4.1

# Создание рабочей директории для сборки
WORKDIR /tmp

# Скачивание и сборка ocserv из исходного кода
RUN wget ftp://ftp.infradead.org/pub/ocserv/ocserv-1.4.1.tar.xz && \
    tar -xf ocserv-1.4.1.tar.xz && \
    cd ocserv-1.4.1 && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-pam \
        --with-utmp \
        --without-seccomp \
        --without-namespaces \
        --without-systemd && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/ocserv-1.4.1* && \
    # Скачивание официального ocserv-exporter от Criteo \
    wget -O /tmp/ocserv-exporter.tar.gz https://github.com/criteo/ocserv-exporter/releases/download/v0.2.2/ocserv-exporter_0.2.2_linux_amd64.tar.gz && \
    tar -xzf /tmp/ocserv-exporter.tar.gz -C /tmp && \
    mv /tmp/ocserv-exporter /usr/local/bin/ocserv-exporter && \
    chmod +x /usr/local/bin/ocserv-exporter && \
    rm -f /tmp/ocserv-exporter.tar.gz && \
    # Очистка build зависимостей \
    apk del .build-deps

# Копирование entrypoint
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
