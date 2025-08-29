FROM alpine:3.22.1

# OCServ Docker Image - собран из исходного кода на Alpine Linux
# Версия ocserv: master (последняя разработческая)
# Базовый образ: Alpine Linux 3.22.1
# Все возможности включены: PAM, RADIUS, GSSAPI, компрессия

# Установка зависимостей для сборки ocserv
RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    automake \
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
    lz4-dev \
    musl-dev \
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
    lz4-libs \
    protobuf-c \
    readline \
    talloc \
    socat \
    rsyslog

# Версия ocserv для сборки
ENV OCSERV_VERSION=master

# Создание рабочей директории для сборки
WORKDIR /tmp

# Скачивание и сборка ocserv из исходного кода
RUN wget https://gitlab.com/openconnect/ocserv/-/archive/master/ocserv-master.tar.gz && \
    tar -xzf ocserv-master.tar.gz && \
    cd ocserv-master && \
    autoreconf -fvi && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-pam \
        --with-gssapi \
        --with-utmp \
        --with-protobuf \
        --enable-compression \
        --disable-systemd && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/ocserv-master* && \
    # Скачивание официального ocserv-exporter от Criteo \
    wget -O /tmp/ocserv-exporter.tar.gz https://github.com/criteo/ocserv-exporter/releases/download/v0.2.1/ocserv-exporter_0.2.1_linux_amd64.tar.gz && \
    tar -xzf /tmp/ocserv-exporter.tar.gz -C /tmp && \
    mv /tmp/ocserv-exporter /usr/local/bin/ocserv-exporter && \
    chmod +x /usr/local/bin/ocserv-exporter && \
    rm -f /tmp/ocserv-exporter.tar.gz && \
    # Очистка build зависимостей \
    apk del .build-deps

# Создание директорий
RUN mkdir -p /etc/ocserv/certs

# Копирование файлов конфигурации
COPY config/ocserv.conf.template /etc/ocserv/ocserv.conf.template
COPY config/passwd /etc/ocserv/passwd
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/metrics-exporter.sh /metrics-exporter.sh

# Генерация самоподписанного сертификата и установка прав
RUN chmod +x /entrypoint.sh /metrics-exporter.sh

# Точка входа
ENTRYPOINT ["/entrypoint.sh"]
