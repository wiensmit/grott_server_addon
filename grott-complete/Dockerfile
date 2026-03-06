ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install Python 3 and curl
RUN apk add --no-cache python3 py3-pip curl

# Download grott from GitHub
RUN curl -L -o /tmp/grott.tar.gz https://github.com/johanmeijer/grott/archive/refs/heads/master.tar.gz && \
    mkdir -p /app && \
    tar xzf /tmp/grott.tar.gz -C /tmp && \
    cp /tmp/grott-master/grott.py /app/ && \
    cp /tmp/grott-master/grottconf.py /app/ && \
    cp /tmp/grott-master/grottdata.py /app/ && \
    cp /tmp/grott-master/grottproxy.py /app/ && \
    cp /tmp/grott-master/grottsniffer.py /app/ && \
    cp /tmp/grott-master/grottserver.py /app/ && \
    rm -rf /tmp/grott.tar.gz /tmp/grott-master

# Install Python dependencies (libscrc needs build tools for CRC support)
RUN apk add --no-cache gcc musl-dev python3-dev && \
    pip3 install --no-cache-dir --break-system-packages \
    paho-mqtt \
    requests \
    libscrc && \
    apk del gcc musl-dev python3-dev

# Note: curl must remain installed - bashio needs it for the HA Supervisor API

WORKDIR /app

# Copy s6 service definitions and startup script
COPY rootfs /
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/grott-proxy/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/grott-server/run

LABEL \
    io.hass.name="Grott Complete" \
    io.hass.description="Growatt inverter monitor with proxy and server API" \
    io.hass.type="addon"
