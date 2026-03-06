#!/usr/bin/with-contenv bashio

# =============================================================================
# Grott Complete Addon - Startup Script
# Generates grott.ini config from addon options
# =============================================================================

CONFIG_PATH="/app/grott.ini"

bashio::log.info "Generating grott.ini configuration..."

# Read all config values into variables first (outside of redirect block)
CFG_MODE=$(bashio::config 'gmode' 'proxy')
CFG_VERBOSE=$(bashio::config 'verbose')
CFG_GROWATT_IP=$(bashio::config 'ggrowattip' '127.0.0.1')
CFG_GROWATT_PORT=$(bashio::config 'ggrowattport' '5781')
CFG_INVTYPE=$(bashio::config 'ginvtype' 'default')
CFG_HA_PLUGIN=$(bashio::config 'ha_plugin')

bashio::log.info "Mode: ${CFG_MODE}"
bashio::log.info "Growatt IP: ${CFG_GROWATT_IP}"
bashio::log.info "Growatt Port: ${CFG_GROWATT_PORT}"

# Determine MQTT settings
MQTT_HOST=""
MQTT_PORT=""
MQTT_USER=""
MQTT_PASS=""

if bashio::config.has_value 'gmqttip'; then
  MQTT_HOST=$(bashio::config 'gmqttip')
  MQTT_PORT=$(bashio::config 'gmqttport' '1883')
  if bashio::config.has_value 'gmqttuser'; then
    MQTT_USER=$(bashio::config 'gmqttuser')
  fi
  if bashio::config.has_value 'gmqttpassword'; then
    MQTT_PASS=$(bashio::config 'gmqttpassword')
  fi
  bashio::log.info "MQTT: using explicit config (${MQTT_HOST}:${MQTT_PORT})"
elif bashio::config.has_value 'mqtt.host'; then
  MQTT_HOST=$(bashio::config 'mqtt.host')
  MQTT_PORT=$(bashio::config 'mqtt.port' '1883')
  if bashio::config.has_value 'mqtt.user'; then
    MQTT_USER=$(bashio::config 'mqtt.user')
  fi
  if bashio::config.has_value 'mqtt.password'; then
    MQTT_PASS=$(bashio::config 'mqtt.password')
  fi
  bashio::log.info "MQTT: using addon mqtt config (${MQTT_HOST}:${MQTT_PORT})"
elif bashio::services.available "mqtt"; then
  MQTT_HOST=$(bashio::services mqtt "host")
  MQTT_PORT=$(bashio::services mqtt "port")
  MQTT_USER=$(bashio::services mqtt "username")
  MQTT_PASS=$(bashio::services mqtt "password")
  bashio::log.info "MQTT: auto-detected from Mosquitto addon (${MQTT_HOST}:${MQTT_PORT})"
else
  bashio::log.warning "No MQTT configuration found! MQTT will be disabled."
fi

# Write the ini file
cat > "${CONFIG_PATH}" << INIEOF
[Generic]
verbose = $([ "${CFG_VERBOSE}" = "true" ] && echo "True" || echo "False")
mode = ${CFG_MODE}
invtype = ${CFG_INVTYPE}

[Growatt]
ip = ${CFG_GROWATT_IP}
port = ${CFG_GROWATT_PORT}

[MQTT]
INIEOF

# Append MQTT config
if [ -n "$MQTT_HOST" ]; then
  cat >> "${CONFIG_PATH}" << MQTTEOF
nomqtt = False
ip = ${MQTT_HOST}
port = ${MQTT_PORT}
auth = $([ -n "${MQTT_USER}" ] && echo "True" || echo "False")
user = ${MQTT_USER}
password = ${MQTT_PASS}
MQTTEOF
else
  echo "nomqtt = True" >> "${CONFIG_PATH}"
fi

# Append extension config for HA plugin
if [ "${CFG_HA_PLUGIN}" = "true" ]; then
  cat >> "${CONFIG_PATH}" << EXTEOF

[extension]
extension = True
extname = grott_ha
extvar = {"ha_mqtt_host": "${MQTT_HOST}", "ha_mqtt_port": ${MQTT_PORT:-1883}, "ha_mqtt_user": "${MQTT_USER}", "ha_mqtt_password": "${MQTT_PASS}"}
EXTEOF
fi

bashio::log.info "Configuration written to ${CONFIG_PATH}"
bashio::log.info "--- grott.ini contents ---"
cat "${CONFIG_PATH}"
bashio::log.info "--- end grott.ini ---"
bashio::log.info "Starting Grott services via s6..."
