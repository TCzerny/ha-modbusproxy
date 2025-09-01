#!/usr/bin/with-contenv bashio
set -e

CONFIG_PATH="/srv/modbus.config.yaml"
LOG_LEVEL=$(bashio::config 'log_level' 'info')

# Fallback if LOG_LEVEL is null or empty
if [ -z "$LOG_LEVEL" ] || [ "$LOG_LEVEL" = "null" ]; then
    LOG_LEVEL="info"
fi

echo "🔧 Generating configuration..."
echo "📊 Log Level: $LOG_LEVEL"

# Create base configuration
cat > "$CONFIG_PATH" <<EOF

logging:
  version: 1
  formatters:
    standard:
      format: "%(asctime)s %(levelname)8s %(name)s: %(message)s"
  handlers:
    console:
      class: logging.StreamHandler
      formatter: standard
  root:
    handlers: ['console']
    level: ${LOG_LEVEL^^}

devices:
EOF

# Read device configuration from HA
echo "📋 Reading Modbus device configuration..."

# Count devices and add them
DEVICE_COUNT=0
VALID_DEVICES=0
while true; do
    # Check if the array index actually exists
    if ! bashio::config.exists "modbus_devices[${DEVICE_COUNT}]" 2>/dev/null; then
        break
    fi
    
    HOST=$(bashio::config "modbus_devices[${DEVICE_COUNT}].host" "" 2>/dev/null || echo "")
    if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
        echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – host is missing"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].port" "502")
    BIND_PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].bind_port" "")
    NAME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].name" "Device $((DEVICE_COUNT+1))")
    # no per-device modbus_id; unit_id_remapping should be used instead
    TIMEOUT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].timeout" "10")
    CONNECTION_TIME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].connection_time" "2")
    
    if [ -z "$BIND_PORT" ] || [ "$BIND_PORT" = "null" ]; then
        echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – bind_port is missing"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    echo "✅ $NAME: $HOST:$PORT -> :$BIND_PORT"
    
    # Add device to YAML configuration
    cat >> "$CONFIG_PATH" <<EOF
  - modbus:
      url: $HOST:$PORT
EOF
    
    # Add optional parameters if set
    TIMEOUT_VAL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].timeout" "" 2>/dev/null || echo "")
    CONNECTION_TIME_VAL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].connection_time" "" 2>/dev/null || echo "")
    
    if [ -n "$TIMEOUT_VAL" ] && [ "$TIMEOUT_VAL" != "null" ]; then
        echo "      timeout: $TIMEOUT_VAL" >> "$CONFIG_PATH"
    fi
    
    if [ -n "$CONNECTION_TIME_VAL" ] && [ "$CONNECTION_TIME_VAL" != "null" ]; then
        echo "      connection_time: $CONNECTION_TIME_VAL" >> "$CONFIG_PATH"
    fi
    
    cat >> "$CONFIG_PATH" <<EOF
    listen:
      bind: 0:$BIND_PORT
EOF
    
    # removed modbus_id handling; rely solely on unit_id_remapping when needed
    
    # Add unit_id_remapping if configured; otherwise auto-map 1 -> modbus_id when provided
    UNIT_ID_REMAPPING=$(bashio::config "modbus_devices[${DEVICE_COUNT}].unit_id_remapping" "" 2>/dev/null || echo "")
    if [ -n "$UNIT_ID_REMAPPING" ] && [ "$UNIT_ID_REMAPPING" != "null" ]; then
        echo "    unit_id_remapping:" >> "$CONFIG_PATH"
        # Parse the remapping JSON and extract key-value pairs
        echo "$UNIT_ID_REMAPPING" | jq -r 'to_entries[] | "      " + (.key | tostring) + ": " + (.value | tostring)' >> "$CONFIG_PATH"
    fi
    
    DEVICE_COUNT=$((DEVICE_COUNT+1))
    VALID_DEVICES=$((VALID_DEVICES+1))
done

if [ "$VALID_DEVICES" -eq 0 ]; then
    echo "❌ ERROR: No valid Modbus devices configured!"
    echo "💡 Please add at least one device in the add-on configuration"
    exit 1
fi

echo "✅ $VALID_DEVICES valid devices configured"

echo "📄 Generated Config:"
cat "$CONFIG_PATH"

# Activate venv if exists
if [ -f "/srv/venv/bin/activate" ]; then
    source /srv/venv/bin/activate
fi

# Start modbus-proxy
echo "🚀 Start Modbus Proxy with Generated Config"
exec modbus-proxy -c "$CONFIG_PATH"
