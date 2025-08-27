# Modbus Proxy Plus - Konfiguration

Dieses Add-on ermöglicht es, mehrere Modbus-Geräte über einen Proxy zu verbinden.

## Konfiguration

### Modbus Devices (JSON)

Die Modbus-Geräte werden als JSON-Array konfiguriert. Hier sind einfache Beispiele:

#### Einfaches Beispiel (1 Gerät):
```json
[
  {
    "name": "Wechselrichter",
    "host": "192.168.1.100",
    "bind_port": 5020
  }
]
```

#### Erweiterte Beispiele:

**Mehrere Geräte:**
```json
[
  {
    "name": "Wechselrichter",
    "host": "192.168.1.100",
    "port": 502,
    "bind_port": 5020,
    "modbus_id": 1,
    "timeout": 10,
    "connection_time": 2
  },
  {
    "name": "Stromzähler",
    "host": "192.168.1.101",
    "port": 502,
    "bind_port": 5021,
    "modbus_id": 1,
    "timeout": 15,
    "connection_time": 1
  }
]
```

### Parameter-Erklärung:

| Parameter | Erforderlich | Standard | Beschreibung |
|-----------|--------------|----------|--------------|
| `name` | Nein | "Device X" | Anzeigename für das Gerät |
| `host` | **Ja** | - | IP-Adresse des Modbus-Geräts |
| `port` | Nein | 502 | Modbus-Port des Geräts |
| `bind_port` | **Ja** | - | Lokaler Port für den Proxy |
| `modbus_id` | Nein | 1 | Modbus Unit ID (1-255) |
| `timeout` | Nein | 10 | Timeout in Sekunden |
| `connection_time` | Nein | 2 | Verbindungszeit in Sekunden |

### Tipps:

1. **Erforderliche Felder:** Nur `host` und `bind_port` sind zwingend erforderlich
2. **Eindeutige Ports:** Jeder `bind_port` muss einzigartig sein
3. **JSON-Validator:** Nutze einen Online-JSON-Validator bei Problemen
4. **Kommentare:** JSON unterstützt keine Kommentare - entferne sie vor dem Speichern

### Beispiel für Copy & Paste:

```json
[{"name":"Mein Gerät","host":"192.168.1.100","bind_port":5020}]
```

## Verwendung

Nach der Konfiguration:
1. Add-on starten
2. Deine Modbus-Clients auf `HOMEASSISTANT_IP:bind_port` konfigurieren
3. Der Proxy leitet alle Anfragen an das entsprechende Gerät weiter

## Fehlersuche

- **"Keine Geräte konfiguriert":** Überprüfe die JSON-Syntax
- **"Host oder bind_port fehlt":** Stelle sicher, dass beide Felder ausgefüllt sind
- **JSON-Fehler:** Verwende einen JSON-Validator online 