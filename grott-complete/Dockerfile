ARG BUILD_FROM=ghcr.io/hassio-addons/base:14.3.3
FROM ${BUILD_FROM}

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install Python 3
RUN apk add --no-cache python3 py3-pip && \
    ln -sf /usr/bin/python3 /usr/bin/python

# Download and install grott from GitHub
RUN apk add --no-cache curl && \
    curl -L -o /tmp/grott.tar.gz https://github.com/johanmeijer/grott/archive/refs/heads/master.tar.gz && \
    mkdir -p /app && \
    tar xzf /tmp/grott.tar.gz -C /tmp && \
    cp /tmp/grott-master/grott.py /app/ && \
    cp /tmp/grott-master/grottconf.py /app/ && \
    cp /tmp/grott-master/grottdata.py /app/ && \
    cp /tmp/grott-master/grottproxy.py /app/ && \
    cp /tmp/grott-master/grottsniffer.py /app/ && \
    cp /tmp/grott-master/grottserver.py /app/ && \
    rm -rf /tmp/grott.tar.gz /tmp/grott-master && \
    apk del curl

# Download grott HA extension for auto-discovery
RUN apk add --no-cache curl && \
    curl -L -o /app/grott_ha.py \
    "https://raw.githubusercontent.com/egguy/grott/feature/ha-extension/examples/Home%20Assistent/grott_ha.py" && \
    apk del curl

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages \
    paho-mqtt \
    requests

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
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"
