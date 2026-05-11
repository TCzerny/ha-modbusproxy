# Multi-arch Python base for Home Assistant apps (Docker BuildKit).
# Default can be overridden by Supervisor/build with --build-arg BUILD_FROM=...
ARG BUILD_FROM=ghcr.io/home-assistant/base-python:3.13-alpine3.23
FROM $BUILD_FROM

LABEL \
    org.opencontainers.image.title="Modbus Proxy" \
    org.opencontainers.image.description="Multi-device Modbus TCP and RTU proxy add-on" \
    org.opencontainers.image.source="https://github.com/TCzerny/ha-modbusproxy" \
    org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /srv

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy our custom modbus-proxy implementation and make it executable
COPY src/modbus_proxy.py /usr/local/bin/modbus-proxy
RUN chmod +x /usr/local/bin/modbus-proxy

# Copy data for add-on
COPY run.sh /
COPY rootfs/ /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
