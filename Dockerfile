# Build stage
FROM ubuntu:22.04 AS builder

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ASTERISK_VERSION=20

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    libncurses5-dev \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    uuid-dev \
    libjansson-dev \
    libcurl4-openssl-dev \
    libogg-dev \
    libvorbis-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libsrtp2-dev \
    libopus-dev \
    libpq-dev \
    libmysqlclient-dev \
    libunbound-dev \
    libedit-dev \
    liblua5.3-dev \
    libpjsip-dev \
    pjproject-dev \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/asterisk

# Copy source code
COPY . .

# Configure and build
RUN ./configure \
    --with-pjproject \
    --with-crypto \
    --with-ssl \
    --with-srtp \
    --with-unbound \
    --with-jansson \
    --with-sqlite3 \
    --with-pgsql \
    --with-mysqlclient \
    --with-lua \
    --with-curl \
    --with-ogg \
    --with-vorbis \
    --with-speex \
    --with-speexdsp \
    --with-opus \
    --with-libedit

RUN make -j$(nproc)
RUN make install
RUN make samples

# Runtime stage
FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libncurses5 \
    libssl3 \
    libxml2 \
    libsqlite3-0 \
    uuid-runtime \
    libjansson4 \
    libcurl4 \
    libogg0 \
    libvorbis0a \
    libspeex1 \
    libspeexdsp1 \
    libsrtp2-1 \
    libopus0 \
    libpq5 \
    libmysqlclient21 \
    libunbound8 \
    libedit2 \
    liblua5.3-0 \
    libpjsip2 \
    pjproject \
    && rm -rf /var/lib/apt/lists/*

# Create asterisk user
RUN useradd -m -s /bin/bash asterisk

# Copy compiled files from builder stage
COPY --from=builder /usr/lib/asterisk/ /usr/lib/asterisk/
COPY --from=builder /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=builder /usr/share/asterisk/ /usr/share/asterisk/
COPY --from=builder /etc/asterisk/ /etc/asterisk/
COPY --from=builder /var/lib/asterisk/ /var/lib/asterisk/
COPY --from=builder /var/spool/asterisk/ /var/spool/asterisk/
COPY --from=builder /var/log/asterisk/ /var/log/asterisk/
COPY --from=builder /var/run/asterisk/ /var/run/asterisk/

# Set permissions
RUN chown -R asterisk:asterisk /etc/asterisk \
    && chown -R asterisk:asterisk /var/lib/asterisk \
    && chown -R asterisk:asterisk /var/spool/asterisk \
    && chown -R asterisk:asterisk /var/log/asterisk \
    && chown -R asterisk:asterisk /var/run/asterisk

# Expose ports
EXPOSE 5060/udp 5060/tcp 5061/udp 5061/tcp 10000-20000/udp

# Switch to asterisk user
USER asterisk

# Set working directory
WORKDIR /etc/asterisk

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD asterisk -rx "core show version" || exit 1

# Start Asterisk
CMD ["/usr/sbin/asterisk", "-f", "-vvvg"]