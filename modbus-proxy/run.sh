#!/usr/bin/with-contenv bashio
set -e

CONFIG_PATH="/srv/modbus.config.yaml"
LOG_LEVEL=$(bashio::config 'log_level' 'info')
AUTO_DETECT_DEVICE=$(bashio::config 'auto_detect_device' 'false')
HAS_RTU_DEVICES="false"

# Auto-detect serial device function
autodetect_serial_device() {
    echo "🔍 Auto-detecting serial device..."
    
    # First try stable by-id paths
    if [ -d "/dev/serial/by-id" ]; then
        DEVICES=$(ls /dev/serial/by-id/ 2>/dev/null | head -1)
        if [ -n "$DEVICES" ]; then
            DETECTED_DEVICE="/dev/serial/by-id/$DEVICES"
            echo "✅ Found stable device: $DETECTED_DEVICE"
            return 0
        fi
    fi
    
    # Fallback to generic paths
    if [ -e "/dev/ttyUSB0" ]; then
        DETECTED_DEVICE="/dev/ttyUSB0"
        echo "✅ Found USB device: $DETECTED_DEVICE"
        return 0
    fi
    
    if [ -e "/dev/ttyACM0" ]; then
        DETECTED_DEVICE="/dev/ttyACM0"
        echo "✅ Found ACM device: $DETECTED_DEVICE"
        return 0
    fi
    
    # Check for any ttyUSB or ttyACM devices
    USB_DEVICES=$(ls /dev/ttyUSB* 2>/dev/null | head -1)
    if [ -n "$USB_DEVICES" ]; then
        DETECTED_DEVICE="$USB_DEVICES"
        echo "✅ Found USB device: $DETECTED_DEVICE"
        return 0
    fi
    
    ACM_DEVICES=$(ls /dev/ttyACM* 2>/dev/null | head -1)
    if [ -n "$ACM_DEVICES" ]; then
        DETECTED_DEVICE="$ACM_DEVICES"
        echo "✅ Found ACM device: $DETECTED_DEVICE"
        return 0
    fi
    
    echo "❌ No serial device found"
    return 1
}

# Fallback if LOG_LEVEL is null or empty
if [ -z "$LOG_LEVEL" ] || [ "$LOG_LEVEL" = "null" ]; then
    LOG_LEVEL="info"
fi

echo "🔧 Generating configuration..."
echo "📊 Log Level: $LOG_LEVEL"

# Map log levels to Python logging levels
case "$LOG_LEVEL" in
    "debug")
        PYTHON_LOG_LEVEL="DEBUG"
        ;;
    "info")
        PYTHON_LOG_LEVEL="INFO"
        ;;
    "warning")
        PYTHON_LOG_LEVEL="WARNING"
        ;;
    "error")
        PYTHON_LOG_LEVEL="ERROR"
        ;;
    *)
        PYTHON_LOG_LEVEL="INFO"
        ;;
esac

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
    level: $PYTHON_LOG_LEVEL

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
    
    PROTOCOL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].protocol" "" 2>/dev/null || echo "")
    HOST=$(bashio::config "modbus_devices[${DEVICE_COUNT}].host" "" 2>/dev/null || echo "")
    DEVICE=$(bashio::config "modbus_devices[${DEVICE_COUNT}].device" "" 2>/dev/null || echo "")
    BIND_PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].bind_port" "")
    NAME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].name" "Device $((DEVICE_COUNT+1))")
    TIMEOUT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].timeout" "10")
    CONNECTION_TIME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].connection_time" "2")
    
    if [ -z "$BIND_PORT" ] || [ "$BIND_PORT" = "null" ]; then
        echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – bind_port is missing"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    # Determine protocol - use explicit protocol or fallback to host/device detection
    if [ -n "$PROTOCOL" ] && [ "$PROTOCOL" != "null" ]; then
        DEVICE_TYPE="$PROTOCOL"
    elif [ -n "$HOST" ] && [ "$HOST" != "null" ]; then
        DEVICE_TYPE="tcp"
    elif [ -n "$DEVICE" ] && [ "$DEVICE" != "null" ]; then
        DEVICE_TYPE="rtu"
    else
        echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – no protocol, host, or device specified"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    # Check if it's a TCP or RTU/Serial device
    if [ "$DEVICE_TYPE" = "tcp" ]; then
        # TCP Modbus device
        PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].port" "502")
        echo "✅ $NAME: TCP $HOST:$PORT -> :$BIND_PORT"
        
        # Add TCP device to YAML configuration
        cat >> "$CONFIG_PATH" <<EOF
  - modbus:
      url: $HOST:$PORT
EOF
    elif [ "$DEVICE_TYPE" = "rtutcp" ]; then
        # Modbus RTU over TCP device
        PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].port" "502")
        echo "✅ $NAME: TCP $HOST:$PORT -> :$BIND_PORT"
        
        # Add TCP device to YAML configuration
        cat >> "$CONFIG_PATH" <<EOF
  - modbus:
      url: rtutcp://$HOST:$PORT
EOF
    elif [ "$DEVICE_TYPE" = "rtu" ]; then
        # RTU/Serial Modbus device
        HAS_RTU_DEVICES="true"
        BAUDRATE=$(bashio::config "modbus_devices[${DEVICE_COUNT}].baudrate" "9600")
        DATABITS=$(bashio::config "modbus_devices[${DEVICE_COUNT}].databits" "8")
        STOPBITS=$(bashio::config "modbus_devices[${DEVICE_COUNT}].stopbits" "1")
        PARITY=$(bashio::config "modbus_devices[${DEVICE_COUNT}].parity" "N")
        
        # Auto-detect device if not specified and auto-detect is enabled
        if [ -z "$DEVICE" ] || [ "$DEVICE" = "null" ]; then
            if [ "$AUTO_DETECT_DEVICE" = "true" ]; then
                echo "🔍 Attempting auto-detection for $NAME..."
                if autodetect_serial_device; then
                    DEVICE="$DETECTED_DEVICE"
                    echo "✅ Auto-detected device for $NAME: $DEVICE"
                else
                    echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – no device specified and auto-detect failed"
                    DEVICE_COUNT=$((DEVICE_COUNT+1))
                    continue
                fi
            else
                echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – no device specified and auto-detect disabled"
                DEVICE_COUNT=$((DEVICE_COUNT+1))
                continue
            fi
        fi
        
        echo "✅ $NAME: RTU $DEVICE ($BAUDRATE/$DATABITS/$PARITY/$STOPBITS) -> :$BIND_PORT"
        
        # Add RTU device to YAML configuration
        cat >> "$CONFIG_PATH" <<EOF
  - modbus:
      url: rtu://$DEVICE
      baudrate: $BAUDRATE
      databits: $DATABITS
      stopbits: $STOPBITS
      parity: $PARITY
EOF
    else
        echo "⚠️ Device #$((DEVICE_COUNT+1)) skipped – invalid protocol: $DEVICE_TYPE"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    # Add optional parameters if set
    TIMEOUT_VAL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].timeout" "" 2>/dev/null || echo "")
    CONNECTION_TIME_VAL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].connection_time" "" 2>/dev/null || echo "")
    
    if [ -n "$TIMEOUT_VAL" ] && [ "$TIMEOUT_VAL" != "null" ]; then
        echo "      timeout: $TIMEOUT_VAL" >> "$CONFIG_PATH"
    fi
    
    if [ -n "$CONNECTION_TIME_VAL" ] && [ "$CONNECTION_TIME_VAL" != "null" ]; then
        echo "      connection_time: $CONNECTION_TIME_VAL" >> "$CONFIG_PATH"
    fi
    
    # Add unit_id_remapping if configured
    UNIT_ID_REMAPPING=$(bashio::config "modbus_devices[${DEVICE_COUNT}].unit_id_remapping" "" 2>/dev/null || echo "")
    if [ -n "$UNIT_ID_REMAPPING" ] && [ "$UNIT_ID_REMAPPING" != "null" ]; then
        echo "    unit_id_remapping:" >> "$CONFIG_PATH"
        # Parse the remapping JSON and extract key-value pairs
        echo "$UNIT_ID_REMAPPING" | jq -r 'to_entries[] | "      " + (.key | tostring) + ": " + (.value | tostring)' >> "$CONFIG_PATH"
    fi
    
    # Add listen configuration
    cat >> "$CONFIG_PATH" <<EOF
    listen:
      bind: 0:$BIND_PORT
EOF
    
    VALID_DEVICES=$((VALID_DEVICES+1))
    DEVICE_COUNT=$((DEVICE_COUNT+1))
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
echo "🔧 Activate Venv..."
if [ -f "/srv/venv/bin/activate" ]; then
    source /srv/venv/bin/activate
fi

# Start modbus-proxy
echo "🚀 Start Modbus Proxy with Generated Config"
exec modbus-proxy -c "$CONFIG_PATH"
