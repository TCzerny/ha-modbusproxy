ARG BUILD_FROM
FROM $BUILD_FROM

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
