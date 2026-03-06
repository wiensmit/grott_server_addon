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

## Inverter Control Scripts

Example Home Assistant scripts for controlling inverter power limits are included in the `examples/` folder.

See [`examples/inverter_scripts.yaml`](examples/inverter_scripts.yaml) for:
- **REST sensors** to read current power limit from each inverter
- **REST command** to set power limits
- **Retry script** that sends a command and verifies it took effect (with configurable retries)
- **Convenience scripts** for turning inverters on (100%) and off (1%)

Copy the sections you need into your HA `configuration.yaml` and replace `YOUR_INVERTER_1` etc. with your actual inverter serial numbers.

> **Important:** Never set power limit to 0% — it can break the inverter configuration. Use 1% for "off".

## Migration from standalone Grott

### Step 1: Record current state (before changing anything)

From your current Grott server, run:

```bash
# Get datalogger serial numbers
curl -X GET "http://<GROTT_SERVER_IP>:5782/datalogger"

# Record current power limits (replace <INVERTER_SERIAL> with your serial)
curl -X GET "http://<GROTT_SERVER_IP>:5782/inverter?command=register&register=03&inverter=<INVERTER_SERIAL>&format=dec"
```

### Step 2: Install and start the addon

Install, configure, and start the addon. Check the addon logs to verify both services start:
- "Starting Grott proxy on port 5279..."
- "Starting Grott server API on port 5782..."

### Step 3: Change datalogger IPs (one at a time)

Use the existing Grott server API to push new IP to each datalogger:

```bash
# Replace <DATALOGGER_SERIAL> with your actual serial and <HA_IP> with your HA IP address
curl -X PUT "http://<GROTT_SERVER_IP>:5782/datalogger?command=register&register=17&datalogger=<DATALOGGER_SERIAL>&value=<HA_IP>"
curl -X PUT "http://<GROTT_SERVER_IP>:5782/datalogger?command=register&register=18&datalogger=<DATALOGGER_SERIAL>&value=5279"
```

**Fallback:** Use the ShinePhone app to change the server IP manually.

### Step 4: Verify

- Check addon logs for incoming data from the migrated datalogger
- Verify MQTT sensors appear in HA (if ha_plugin is enabled)
- Test a register read: `curl http://<HA_IP>:5782/inverter?command=register&register=03&inverter=<INVERTER_SERIAL>&format=dec`

### Step 5: Migrate remaining dataloggers

Once verified, change the remaining dataloggers to point to `<HA_IP>:5279`.

### Step 6: Decommission old server

Stop the Grott services on the TrueNAS VM.

## Rollback

1. Stop the addon in HA
2. Change datalogger IPs back to your old Grott server via ShinePhone app
3. Restart Grott services on your old server
