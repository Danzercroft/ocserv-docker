FROM alpine:3.23.3

# OCServ Docker Image - собран из исходного кода на Alpine Linux
# Версия ocserv: 1.4.1 (релизная)
# Базовый образ: Alpine Linux 3.22.3
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
RUN wget https://gitlab.com/openconnect/ocserv/-/archive/1.4.1/ocserv-1.4.1.tar.gz && \
    tar -xzf ocserv-1.4.1.tar.gz && \
    cd ocserv-1.4.1 && \
    meson setup build \
        --prefix=/usr \
        --sysconfdir=/etc \
        -Dpam=enabled \
        -Dgssapi=enabled \
        -Dutmp=enabled \
        -Dseccomp=disabled \
        -Dnamespaces=disabled \
        -Dsystemd=disabled && \
    ninja -C build && \
    ninja -C build install && \
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
