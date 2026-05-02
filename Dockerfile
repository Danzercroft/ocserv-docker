FROM alpine:3.23.4

# OCServ Docker Image - собран из исходного кода на Alpine Linux
# Версия ocserv: последняя релизная версия с GitLab
# Базовый образ: Alpine Linux 3.23.4
# Все возможности включены: PAM, RADIUS, GSSAPI

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
ENV OCSERV_VERSION=latest

# Создание рабочей директории для сборки
WORKDIR /tmp

# Установка зависимостей, скачивание и сборка ocserv, а затем очистка
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
    wget && \
    git clone https://gitlab.com/openconnect/ocserv.git && \
    cd ocserv && \
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1)) && \
    git checkout $LATEST_TAG && \
    meson setup build \
        --prefix=/usr \
        --sysconfdir=/etc \
        -Dpam=enabled \
        -Dseccomp=disabled && \
    meson compile -C build && \
    meson install -C build && \
    cd / && \
    rm -rf /tmp/ocserv* && \
    wget -O /tmp/ocserv-exporter.tar.gz https://github.com/criteo/ocserv-exporter/releases/download/v0.2.2/ocserv-exporter_0.2.2_linux_amd64.tar.gz && \
    tar -xzf /tmp/ocserv-exporter.tar.gz -C /tmp && \
    mv /tmp/ocserv-exporter /usr/local/bin/ocserv-exporter && \
    chmod +x /usr/local/bin/ocserv-exporter && \
    rm -f /tmp/ocserv-exporter.tar.gz && \
    apk del .build-deps

# Копирование entrypoint
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
