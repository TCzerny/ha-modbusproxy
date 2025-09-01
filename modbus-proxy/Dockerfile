ARG BUILD_FROM
FROM $BUILD_FROM

# Install python + pip + serial support
WORKDIR /srv
RUN \
  apk add --no-cache \
    python3 py3-pip py3-yaml \
    pyserial

# Prepare venv
RUN cd /srv && python3 -m venv venv

# Copy our custom modbus-proxy implementation
COPY src/modbus_proxy.py /srv/venv/bin/modbus-proxy

# Install dependencies
RUN cd /srv && source ./venv/bin/activate && \
    pip install PyYAML pyserial

# Make executable
RUN chmod +x /srv/venv/bin/modbus-proxy

# Add venv to PATH
ENV PATH="/srv/venv/bin:$PATH"

# Copy data for add-on
WORKDIR /
COPY run.sh /
COPY rootfs /
WORKDIR /srv

RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
