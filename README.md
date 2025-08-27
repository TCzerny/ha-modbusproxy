# Home Assistant Add-on: Modbus Proxy Plus

[![License][license-shield]](LICENSE)

A powerful multi-device Modbus TCP proxy for Home Assistant that allows multiple clients to connect to Modbus servers that typically only support a single connection.

## About

Most Modbus TCP servers only allow a single client connection and reject additional clients. This add-on creates a proxy that can handle multiple client connections simultaneously while maintaining a single connection to each Modbus server.

**Key Features:**
- 🔄 Multiple client connections to single Modbus server
- 🌐 Support for multiple Modbus devices
- ⚙️ Easy configuration through Home Assistant UI
- 🔧 Configurable timeouts and connection parameters
- 📊 Built-in logging and monitoring
- 🚀 Host network mode for optimal performance

## Installation

### Method 1: One-Click Installation (Recommended)

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FTCzerny%2Fha-modbusproxy)

### Method 2: Manual Installation

1. Navigate to **Settings** → **Addons** → **Add-on Store** in your Home Assistant
2. Click the **⋮** menu in the top right corner
3. Select **Repositories**
4. Add this repository URL: `https://github.com/TCzerny/ha-modbusproxy`
5. Find **Modbus Proxy Plus** in the add-on store
6. Click **Install**

## Configuration

### Basic Configuration Example

```yaml
- name: "Solar Inverter"
  host: "192.168.1.100"
  bind_port: 502
```

### Configuration Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `name` | No | `Device X` | Friendly name for the device |
| `host` | **Yes** | - | IP address of the Modbus server |
| `port` | No | `502` | Modbus TCP port of the server |
| `bind_port` | **Yes** | - | Local port where proxy will listen |
| `modbus_id` | No | `1` | Modbus unit/slave ID |
| `unit_id_remapping` | No | - | Map incoming unit ID to target unit ID (e.g., `1: 10`) |
| `timeout` | No | `10.0` | Connection timeout in seconds |
| `connection_time` | No | `2.0` | Time to establish connection in seconds |
| `log_level` | No | `info` | Logging level: `debug`, `info`, `warning`, `error` |

### Advanced Configuration Examples

#### Unit ID Remapping

The `unit_id_remapping` feature allows you to map incoming unit IDs to different target unit IDs on the Modbus server. This is useful when:

- Your Modbus client expects a specific unit ID (e.g., 1)
- The actual Modbus server has the device on a different unit ID (e.g., 10)
- You want to virtualize unit IDs for different clients

**Example:** `unit_id_remapping: {1: 10}` means:
- When a client sends a request to unit ID 1, it gets forwarded to unit ID 10 on the server
- All responses from unit ID 10 appear as if they came from unit ID 1

**Note:** Each device can only have one remapping configuration.

#### Multiple Solar Inverters with Unit ID Remapping
```yaml
modbus_devices:
  - name: "Inverter 1"
    host: "192.168.1.100"
    port: 502
    bind_port: 503
    timeout: 10.0
    connection_time: 2.0
  - name: "Inverter 2"
    host: "192.168.1.101"
    bind_port: 504
    timeout: 10.0
    connection_time: 2.0
  - name: "Inverter 3"
    host: "192.168.1.102"
    bind_port: 505
```

## Usage

### Step 1: Stop Existing Clients
Before starting the proxy, stop all clients currently connected to your Modbus servers. The server needs time to release existing connections.

**For SolarEdge Modbus integration:**
1. Go to **Settings** → **Devices & Services**
2. Find your SolarEdge integration
3. Click **Configure**
4. Temporarily disable or change the host

### Step 2: Configure the Add-on
1. Go to **Settings** → **Addons** → **Modbus Proxy Plus**
2. Click the **Configuration** tab
3. Add your Modbus devices using the examples above
4. Click **Save**

### Step 3: Start the Add-on
1. Click the **Info** tab
2. Click **Start**
3. Monitor the logs for successful connections

### Step 4: Update Your Clients
Configure your Modbus clients to connect to:
- **Host:** Your Home Assistant IP address
- **Port:** The `bind_port` you configured for each device

## Troubleshooting

### Common Issues

#### "Address already in use" Error
```
OSError: [Errno 98] error while attempting to bind on address ('0.0.0.0', 502): address in use
```
**Solution:** Change the `bind_port` to an unused port (e.g., 505, 506, etc.)

#### "Connection refused" Error
```
Connection refused to 192.168.1.100:502
```
**Solutions:**
1. Verify the Modbus server IP address and port
2. Ensure the Modbus server is running and accessible
3. Check firewall settings on both devices
4. Stop other clients connected to the Modbus server

#### "Timeout" Errors
**Solutions:**
1. Increase the `timeout` value in configuration
2. Increase the `connection_time` value
3. Check network connectivity and latency

### Debugging

Enable debug logging to get more detailed information:

```yaml
log_level: "debug"
```

Then check the add-on logs:
1. Go to **Settings** → **Addons** → **Modbus Proxy Plus**
2. Click the **Log** tab
3. Look for connection attempts and error messages

### Network Configuration

This add-on uses `host_network: true` which means:
- ✅ Direct access to host network interfaces
- ✅ No need to configure port mappings in add-on settings
- ✅ Optimal performance with minimal network overhead
- ⚠️ Ports must be unique across all services on your host


## Support

### Getting Help

1. **Check the logs** first for error messages
2. **Review this README** for configuration examples
3. **Search existing issues** on GitHub
4. **Create a new issue** with:
   - Your configuration (remove sensitive data)
   - Complete log output
   - Description of the problem

### Reporting Issues

When reporting issues, please include:

```yaml
# Your anonymized configuration
modbus_devices:
  - name: "Device 1"
    host: "192.168.1.XXX"  # Replace with XXX
    port: 502
    bind_port: 5020
# ... rest of config
```

And the complete log output from the add-on.

## Credits

This add-on is based on:
- **Original add-on:** [Akulatraxas/ha-modbusproxy](https://github.com/Akulatraxas/ha-modbusproxy)
- **Modbus Proxy Library:** [tiagocoutinho/modbus-proxy](https://github.com/tiagocoutinho/modbus-proxy)

## License

See the [LICENSE](LICENSE) file for details.

---