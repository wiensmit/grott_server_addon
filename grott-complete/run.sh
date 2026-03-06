#!/usr/bin/with-contenv bashio

# =============================================================================
# Grott Complete Addon - Startup Script
# Generates grott.ini config from addon options, then s6 starts both services
# =============================================================================

CONFIG_PATH="/app/grott.ini"

bashio::log.info "Generating grott.ini configuration..."

# --- Generic section ---
{
  echo "[Generic]"

  if bashio::config.true 'verbose'; then
    echo "verbose = True"
  fi

  val=$(bashio::config 'gmode')
  echo "mode = ${val}"

  if bashio::config.has_value 'gminrecl'; then
    echo "minrecl = $(bashio::config 'gminrecl')"
  fi

  if bashio::config.has_value 'ggrottip'; then
    echo "ip = $(bashio::config 'ggrottip')"
  fi

  if bashio::config.has_value 'ggrottport'; then
    echo "port = $(bashio::config 'ggrottport')"
  fi

  if bashio::config.has_value 'gblockcmd' && bashio::config.true 'gblockcmd'; then
    echo "blockcmd = True"
  fi

  if bashio::config.has_value 'gnoipf' && bashio::config.true 'gnoipf'; then
    echo "noipf = True"
  fi

  if bashio::config.has_value 'gtime'; then
    echo "time = $(bashio::config 'gtime')"
  fi

  if bashio::config.has_value 'gsendbuf'; then
    if bashio::config.true 'gsendbuf'; then
      echo "sendbuf = True"
    else
      echo "sendbuf = False"
    fi
  fi

  if bashio::config.has_value 'gcompat' && bashio::config.true 'gcompat'; then
    echo "compat = True"
  fi

  if bashio::config.has_value 'gvalueoffset'; then
    echo "valueoffset = $(bashio::config 'gvalueoffset')"
  fi

  if bashio::config.has_value 'ginverterid'; then
    echo "inverterid = $(bashio::config 'ginverterid')"
  fi

  if bashio::config.has_value 'ginvtype'; then
    echo "invtype = $(bashio::config 'ginvtype')"
  fi

  if bashio::config.has_value 'gdecrypt'; then
    if bashio::config.true 'gdecrypt'; then
      echo "decrypt = True"
    else
      echo "decrypt = False"
    fi
  fi

  echo ""

  # --- Growatt section ---
  echo "[Growatt]"
  echo "ip = $(bashio::config 'ggrowattip')"
  echo "port = $(bashio::config 'ggrowattport')"
  echo ""

  # --- MQTT section ---
  echo "[MQTT]"

  # Determine MQTT settings: explicit config > addon mqtt config > HA auto-discovery
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
  elif bashio::config.has_value 'mqtt.host'; then
    MQTT_HOST=$(bashio::config 'mqtt.host')
    MQTT_PORT=$(bashio::config 'mqtt.port' '1883')
    if bashio::config.has_value 'mqtt.user'; then
      MQTT_USER=$(bashio::config 'mqtt.user')
    fi
    if bashio::config.has_value 'mqtt.password'; then
      MQTT_PASS=$(bashio::config 'mqtt.password')
    fi
  elif bashio::services.available "mqtt"; then
    bashio::log.info "Using auto-detected MQTT from Mosquitto addon"
    MQTT_HOST=$(bashio::services mqtt "host")
    MQTT_PORT=$(bashio::services mqtt "port")
    MQTT_USER=$(bashio::services mqtt "username")
    MQTT_PASS=$(bashio::services mqtt "password")
  else
    bashio::log.warning "No MQTT configuration found! MQTT will be disabled."
    echo "nomqtt = True"
  fi

  if [ -n "$MQTT_HOST" ]; then
    echo "nomqtt = False"
    echo "ip = ${MQTT_HOST}"
    echo "port = ${MQTT_PORT}"
    if [ -n "$MQTT_USER" ]; then
      echo "auth = True"
      echo "user = ${MQTT_USER}"
      echo "password = ${MQTT_PASS}"
    else
      echo "auth = False"
    fi
  fi

  if bashio::config.has_value 'gmqtttopic'; then
    echo "topic = $(bashio::config 'gmqtttopic')"
  fi

  if bashio::config.has_value 'gmqttinverterintopic' && bashio::config.true 'gmqttinverterintopic'; then
    echo "inverterintopic = True"
  fi

  echo ""

  # --- Extension section (HA plugin) ---
  if bashio::config.true 'ha_plugin'; then
    echo "[extension]"
    echo "extension = True"
    echo "extname = grott_ha"
    # Build extvar with MQTT credentials for the HA plugin
    EXTVAR="{\"ha_mqtt_host\": \"${MQTT_HOST}\", \"ha_mqtt_port\": ${MQTT_PORT:-1883}, \"ha_mqtt_user\": \"${MQTT_USER}\", \"ha_mqtt_password\": \"${MQTT_PASS}\"}"
    echo "extvar = ${EXTVAR}"
  fi

} > "${CONFIG_PATH}"

bashio::log.info "Configuration written to ${CONFIG_PATH}"

if bashio::config.true 'verbose'; then
  bashio::log.info "--- grott.ini contents ---"
  cat "${CONFIG_PATH}"
  bashio::log.info "--- end grott.ini ---"
fi

bashio::log.info "Starting Grott services via s6..."
