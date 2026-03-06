# Grott Complete - Home Assistant Addon

Runs both the Grott proxy and Grott server API as a single Home Assistant addon.

- **Grott proxy** (port 5279): Intercepts datalogger traffic, publishes to MQTT
- **Grott server API** (port 5781/5782): Emulates Growatt server locally. HTTP API on port 5782 for reading/writing inverter registers (power limit control)

**Note:** By default, the proxy forwards to grottserver locally (127.0.0.1:5781). This is required for register read/write commands to work. If you change `ggrowattip` to `server.growatt.com`, data will go to Growatt cloud but you will lose the ability to send commands to inverters via the API.

## Installation

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**
2. Click the three-dot menu (top right) > **Repositories**
3. Add your repository URL
4. Refresh the page, find "Grott Complete", and install it
5. Configure the addon (see below), then start it

## Configuration

Most settings auto-detect. The key options:

| Option | Default | Description |
|--------|---------|-------------|
| `gmode` | `proxy` | Operating mode (proxy or sniff) |
| `ggrowattip` | `127.0.0.1` | Where proxy forwards data. Keep as 127.0.0.1 for register commands |
| `ggrowattport` | `5781` | Growatt server port (5781 for local grottserver) |
| `verbose` | `false` | Enable debug logging |
| `ha_plugin` | `true` | Enable HA auto-discovery via MQTT |

**MQTT** is auto-detected from the Mosquitto addon. No manual MQTT config needed.

## Migration from standalone Grott

### Step 1: Record current state (before changing anything)

From your current Grott server, run:

```bash
# Get datalogger serial numbers
curl -X GET "http://192.168.2.252:5782/datalogger"

# Record current power limits
curl -X GET "http://192.168.2.252:5782/inverter?command=register&register=03&inverter=BLK4CBJ08S&format=dec"
curl -X GET "http://192.168.2.252:5782/inverter?command=register&register=03&inverter=FVJ7CJJ0JS&format=dec"
curl -X GET "http://192.168.2.252:5782/inverter?command=register&register=03&inverter=FUJ6CFP07S&format=dec"
```

### Step 2: Install and start the addon

Install, configure, and start the addon. Check the addon logs to verify both services start:
- "Starting Grott proxy on port 5279..."
- "Starting Grott server API on port 5782..."

### Step 3: Change datalogger IPs (one at a time)

Use the existing Grott server API to push new IP to each datalogger:

```bash
# Replace <DATALOGGER_SERIAL> with your actual serial
curl -X PUT "http://192.168.2.252:5782/datalogger?command=register&register=17&datalogger=<DATALOGGER_SERIAL>&value=192.168.2.56"
curl -X PUT "http://192.168.2.252:5782/datalogger?command=register&register=18&datalogger=<DATALOGGER_SERIAL>&value=5279"
```

**Fallback:** Use the ShinePhone app to change the server IP manually.

### Step 4: Verify

- Check addon logs for incoming data from the migrated datalogger
- Verify MQTT sensors appear in HA (if ha_plugin is enabled)
- Test a register read: `curl http://192.168.2.56:5782/inverter?command=register&register=03&inverter=BLK4CBJ08S&format=dec`

### Step 5: Migrate remaining dataloggers

Once verified, change the remaining dataloggers to point to 192.168.2.56:5279.

### Step 6: Decommission old server

Stop the Grott services on the TrueNAS VM.

## Rollback

1. Stop the addon in HA
2. Change datalogger IPs back to 192.168.2.252 via ShinePhone app
3. Restart Grott services on the TrueNAS VM
