# Grott Complete - Home Assistant Addon

A Home Assistant addon that packages both **Grott** (the Growatt inverter monitor) and **Grott Server** (the Growatt server emulator with HTTP API) into a single addon. This gives you local monitoring and full register-level control of your Growatt inverters directly from Home Assistant.

## What this addon does

Growatt solar inverters communicate with Growatt's cloud servers via dataloggers (ShineWiFi/ShineLAN). Grott sits between the datalogger and the server, intercepting the data and making it available locally.

This addon runs two components:

- **Grott proxy** (port 5279) - Intercepts datalogger traffic and publishes inverter data (production, voltage, current, temperature, etc.) to MQTT. The HA plugin creates sensor entities automatically via MQTT auto-discovery.
- **Grott server** (port 5782) - Emulates the Growatt server locally and exposes an HTTP API for reading and writing inverter registers. This enables direct control of inverter settings like power limits.

### Architecture

```
Growatt Inverters
    |
Dataloggers (ShineWiFi/ShineLAN)
    |
    v
Home Assistant
  +-- Grott Complete Addon
  |     +-- Grott Proxy (port 5279) -- receives datalogger data
  |     |     +-- publishes to MQTT --> HA auto-discovery sensors
  |     |     +-- forwards to Grott Server (127.0.0.1:5781)
  |     +-- Grott Server (port 5782) -- HTTP API for register control
  |           +-- queues commands --> relays back through proxy to inverters
  +-- MQTT Broker (Mosquitto addon)
  +-- HA Scripts (REST sensors + commands for power limit control)
```

## Quick start

1. Add this repository to your Home Assistant addon store
2. Install and start "Grott Complete"
3. Point your dataloggers to your HA IP address on port 5279
4. Inverter sensors appear automatically via MQTT

See [`grott-complete/README.md`](grott-complete/README.md) for detailed installation, configuration, and migration instructions.

See [`grott-complete/examples/`](grott-complete/examples/) for Home Assistant scripts to control inverter power limits with retry and verification.

## Credits

This addon is built on the work of:

- **[Grott](https://github.com/johanmeijer/grott)** by Johan Meijer - The core Growatt monitor that intercepts inverter data. Grott supports proxy and sniff modes, MQTT, InfluxDB, and PVOutput. This addon packages `grott.py`, `grottserver.py`, and all supporting modules from this project.

- **[Grott Home Assistant Add-on](https://github.com/egguy/grott-home-assistant-add-on)** by egguy - The original HA addon for Grott that inspired this project. The HA auto-discovery plugin (`grott_ha.py`) used in this addon comes from egguy's fork. This addon extends the concept by also including `grottserver.py` for full register-level inverter control.

- **[Growatt](https://www.growatt.com/)** - Manufacturer of the solar inverters and dataloggers.

## Differences from existing addons

| Feature | egguy/grott addon | This addon |
|---------|-------------------|------------|
| Grott proxy (monitoring) | Yes | Yes |
| MQTT + HA auto-discovery | Yes | Yes |
| Grott server API (register control) | No | Yes |
| Set inverter power limits from HA | No | Yes |
| Read inverter registers via HTTP | No | Yes |

The key addition is `grottserver.py`, which emulates the Growatt server and provides an HTTP API for reading and writing inverter/datalogger registers. This enables automation scenarios like turning inverters on/off based on grid conditions or time schedules.

## License

This project packages open-source software. See the original repositories for their respective licenses:
- [Grott](https://github.com/johanmeijer/grott) (MIT License)
- [Grott HA Add-on](https://github.com/egguy/grott-home-assistant-add-on)
