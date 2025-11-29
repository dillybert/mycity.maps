start_container() {
  local name="$1"
  local command="$2"
  local port="${3:-N/A}"

  if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
      log_info "Service is already running: ${name}"
      exit 0
    else
      log_warn "Removing old stopped service: ${name}"
      docker rm "$name" >/dev/null 2>&1 || true
    fi
  fi

  log_info "Starting service: ${name} (port: ${port})..."
  eval "$command" &>>"$LOG_FILE"
  log_info "Service is started: ${name}"
}

start_postgis() {
  log_info "Starting PostGIS database..."

  local cmd="docker run -d \
    --name ${POSTGIS_CONTAINER_NAME} \
    -e POSTGRES_DB=${POSTGIS_DB} \
    -e POSTGRES_USER=${POSTGIS_USER} \
    -e POSTGRES_PASSWORD=${POSTGIS_PASSWORD} \
    -p ${POSTGIS_PORT}:5432 \
    ${POSTGIS_IMAGE}"

  start_container "$POSTGIS_CONTAINER_NAME" "$cmd" "$POSTGIS_PORT"

  log_info "Waiting for PostGIS database to start..."

  until docker exec "$POSTGIS_CONTAINER_NAME" psql -p 5432 -U "$POSTGIS_USER" -d "$POSTGIS_DB" -c "SELECT 1" &>>"$LOG_FILE"; do
    log_warn "PostGIS database is not ready. Retrying in 3 seconds..."
    sleep 3
  done
  log_info "PostGIS database is ready."
  
  log_info "PostGIS database is successfully started and ready to use."
  touch "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_ready.tmp"
}
register "start" "postgis" "Start PostGIS container" "start_postgis"

start_osrm() {
  if [ ! -f "$TEMP_DIR/${OSRM_CONTAINER_NAME}_prepared.tmp" ]; then
    log_error "OSRM data is not prepared! Please prepare the OSRM data first."
    exit 1
  fi

  log_info "Starting OSRM service..."

  local cmd="docker run -d \
    --name ${OSRM_CONTAINER_NAME} \
    -p ${OSRM_PORT}:5000 \
    -v ${OSRM_DIR}:/data \
    ${OSRM_IMAGE} \
    osrm-routed --algorithm ${OSRM_ALGO} /data/$(basename ${COMPRESSED_OSM_PBF_FILE%.osm.pbf}).osrm"

  start_container "$OSRM_CONTAINER_NAME" "$cmd" "$OSRM_PORT"

  until curl -s "http://${HOST_IP}:${OSRM_PORT}" > /dev/null; do
    log_warn "OSRM service is not ready. Retrying in 3 seconds..."
    sleep 3
  done

  log_info "OSRM service is successfully started and ready to use."
  touch "$TEMP_DIR/${OSRM_CONTAINER_NAME}_ready.tmp"
}
register "start" "osrm" "Start OSRM container" "start_osrm"

start_nominatim() {
  log_info "Starting Nominatim service..."
  
  local cmd="docker run -d \
    --name ${NOMINATIM_CONTAINER_NAME} \
    -v ${COMPRESSED_OSM_PBF_FILE}:/data.osm.pbf \
    -e PBF_PATH=/data.osm.pbf \
    -e NOMINATIM_PASSWORD=${NOMINATIM_PASSWORD} \
    -e REVERSE_ONLY=true \
    -p ${NOMINATIM_REVERSE_PORT}:8080 \
    -p ${NOMINATIM_DB_PORT}:5432 \
    ${NOMINATIM_IMAGE}"

  start_container "$NOMINATIM_CONTAINER_NAME" "$cmd" "$NOMINATIM_REVERSE_PORT"

  until curl -s "http://${HOST_IP}:${NOMINATIM_REVERSE_PORT}" > /dev/null; do
    log_warn "Nominatim service is not ready. Retrying in 3 seconds..."
    sleep 3
  done

  log_info "Nominatim service is successfully started and ready to use."
  touch "$TEMP_DIR/${NOMINATIM_CONTAINER_NAME}_ready.tmp"
}
register "start" "nominatim" "Start Nominatim container" "start_nominatim"

start_photon() {
  if [[ ! -f "$TEMP_DIR/${PHOTON_SERVICE_NAME}_prepared.tmp" ]]; then
    log_error "Photon data is not prepared! Please prepare the Photon data first."
    exit 1
  fi

  local pid=""
  log_info "Starting Photon service..."

  java -jar ${PHOTON_JAR_FILE} \
    -listen-port ${PHOTON_PORT} \
    -data-dir $PHOTON_DATA_DIR &>>"$LOG_FILE" &

  pid=$!

  until curl -s "http://${HOST_IP}:${PHOTON_PORT}" > /dev/null; do
    log_warn "Photon service is not ready. Retrying in 3 seconds..."
    sleep 3
  done

  log_info "Photon service is successfully started and ready to use."
  echo "$pid" > "$TEMP_DIR/${PHOTON_SERVICE_NAME}_ready.tmp"
}
register "start" "photon" "Start Photon container" "start_photon"

start_martin() {
  if [[ ! -f "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_started.tmp" && ! -f "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_imported.tmp" ]]; then
    log_error "PostGIS database is not ready! Please prepare the PostGIS database first."
    exit 1
  fi

  log_info "Starting Martin service..."

  local cmd="docker run -d \
    --name ${MARTIN_CONTAINER_NAME} \
    --net=host \
    -p ${MARTIN_PORT}:3000 \
    -v ${MARTIN_SPRITES_DIR}:/sprites \
    -v ${MARTIN_FONTS_DIR}:/fonts \
    ${MARTIN_IMAGE} \
    $([[ "$MARTIN_WEBUI" == true ]] && echo "--webui enable-for-all") \
    --sprite /sprites \
    --font /fonts \
    ${POSTGIS_URL}"
    
  start_container "$MARTIN_CONTAINER_NAME" "$cmd" "$MARTIN_PORT"

  until curl -s "http://${HOST_IP}:${MARTIN_PORT}" > /dev/null; do
    log_warn "Martin service is not ready. Retrying in 3 seconds..."
    sleep 3
  done

  log_info "Martin service is successfully started and ready to use."
  touch "$TEMP_DIR/${MARTIN_CONTAINER_NAME}_ready.tmp"
}
register "start" "martin" "Start Martin container" "start_martin"

start_maputnik() {
  if [[ ! -f "$TEMP_DIR/${MARTIN_CONTAINER_NAME}_ready.tmp" ]]; then
    log_error "Martin service is not ready! Please start the Martin service first."
    exit 1
  fi

  log_info "Checking IP address..."
  sed -i "s|http://[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}\(:[0-9]\+\)\?|http://$HOST_IP\2|g" "$MAPUTNIK_STYLE_FILE"

  log_info "Starting Maputnik service..."

  local cmd="docker run -d \
    --name ${MAPUTNIK_CONTAINER_NAME} \
    -p ${MAPUTNIK_PORT}:8000 \
    -v ${MAPUTNIK_STYLE_FILE}:/style.json \
    ${MAPUTNIK_IMAGE} \
    --file /style.json \
    --watch"

  start_container "$MAPUTNIK_CONTAINER_NAME" "$cmd" "$MAPUTNIK_PORT"

  until curl -s "http://${HOST_IP}:${MAPUTNIK_PORT}" > /dev/null; do
    log_warn "Maputnik service is not ready. Retrying in 3 seconds..."
    sleep 3
  done

  log_info "Maputnik service is successfully started and ready to use."
  touch "$TEMP_DIR/${MAPUTNIK_CONTAINER_NAME}_ready.tmp"
}
register "start" "maputnik" "Start Maputnik container" "start_maputnik"
