#!/usr/bin/with-contenv bashio
set -e

CONFIG_PATH="/srv/modbus.config.yaml"
LOG_LEVEL=$(bashio::config 'log_level' 'info')

# Fallback wenn LOG_LEVEL null oder leer ist
if [ -z "$LOG_LEVEL" ] || [ "$LOG_LEVEL" = "null" ]; then
    LOG_LEVEL="info"
fi

echo "🔧 Konfiguration wird generiert..."
echo "📊 Log Level: $LOG_LEVEL"

# Erstelle Basis-Konfiguration
cat > "$CONFIG_PATH" <<EOF

logging:
  version: 1
  handlers:
    console:
      class: logging.StreamHandler
  root:
    handlers: ['console']
    level: ${LOG_LEVEL^^}

devices:
EOF

# Lese Geräte-Konfiguration von HA
echo "📋 Lese Modbus-Geräte Konfiguration..."

# Zähle Geräte und füge sie hinzu
DEVICE_COUNT=0
VALID_DEVICES=0
while true; do
    # Prüfe erst ob der Array-Index überhaupt existiert
    if ! bashio::config.exists "modbus_devices[${DEVICE_COUNT}]" 2>/dev/null; then
        break
    fi
    
    HOST=$(bashio::config "modbus_devices[${DEVICE_COUNT}].host" "" 2>/dev/null || echo "")
    if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
        echo "⚠️ Gerät #$((DEVICE_COUNT+1)) übersprungen – host fehlt"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].port" "502")
    BIND_PORT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].bind_port" "")
    NAME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].name" "Device $((DEVICE_COUNT+1))")
    MODBUS_ID=$(bashio::config "modbus_devices[${DEVICE_COUNT}].modbus_id" "1")
    TIMEOUT=$(bashio::config "modbus_devices[${DEVICE_COUNT}].timeout" "10")
    CONNECTION_TIME=$(bashio::config "modbus_devices[${DEVICE_COUNT}].connection_time" "2")
    
    if [ -z "$BIND_PORT" ] || [ "$BIND_PORT" = "null" ]; then
        echo "⚠️ Gerät #$((DEVICE_COUNT+1)) übersprungen – bind_port fehlt"
        DEVICE_COUNT=$((DEVICE_COUNT+1))
        continue
    fi
    
    echo "✅ $NAME: $HOST:$PORT -> :$BIND_PORT"
    
    # Füge Gerät zur YAML-Konfiguration hinzu
    cat >> "$CONFIG_PATH" <<EOF
  - modbus:
      url: $HOST:$PORT
EOF
    
    # Optionale Parameter nur hinzufügen wenn gesetzt
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
    
    # Modbus ID nur hinzufügen wenn gesetzt und nicht 1 (Standard)
    MODBUS_ID_VAL=$(bashio::config "modbus_devices[${DEVICE_COUNT}].modbus_id" "" 2>/dev/null || echo "")
    if [ -n "$MODBUS_ID_VAL" ] && [ "$MODBUS_ID_VAL" != "null" ] && [ "$MODBUS_ID_VAL" != "1" ]; then
        echo "    modbus_id: $MODBUS_ID_VAL" >> "$CONFIG_PATH"
    fi
    
    DEVICE_COUNT=$((DEVICE_COUNT+1))
    VALID_DEVICES=$((VALID_DEVICES+1))
done

if [ "$VALID_DEVICES" -eq 0 ]; then
    echo "❌ FEHLER: Keine gültigen Modbus-Geräte konfiguriert!"
    echo "💡 Bitte füge mindestens ein Gerät in der Add-on Konfiguration hinzu"
    exit 1
fi

echo "✅ $VALID_DEVICES gültige Geräte konfiguriert"

echo "📄 Generated Config:"
cat "$CONFIG_PATH"

# Aktiviere venv falls vorhanden
if [ -f "/srv/venv/bin/activate" ]; then
    echo "🔄 Aktiviere Python venv..."
    source /srv/venv/bin/activate
fi

# Starte modbus-proxy
echo "🚀 Starte Modbus Proxy mit $CONFIG_PATH"
exec modbus-proxy -c "$CONFIG_PATH"
