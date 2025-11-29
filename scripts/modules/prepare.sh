prepare_osm_file() {
  log_info "Checking OSM file..."

  if [ ! -f "$OSM_FILE" ]; then
    log_error "${YELLOW}${OSM_FILE}${NC} file not found!"
    exit 1
  fi
  log_info "OSM file found: ${OSM_FILE}"

  log_info "Preparing OSM file..."

  log_info "Filtering OSM file..."
  osmfilter "$OSM_FILE" --drop-tags="action= fixme= source= created_by= note= timestamp=" --fake-version -o="$TEMP_DIR/filtered.osm" &>>"$LOG_FILE"
  log_info "Done filtering OSM file."

  log_info "Normalizing OSM ID's..."
  osmium renumber "$TEMP_DIR/filtered.osm" -o "$TEMP_DIR/renumbered.osm" --overwrite &>>"$LOG_FILE" && rm "$TEMP_DIR/filtered.osm" &> /dev/null
  log_info "Done normalizing OSM ID's."

  log_info "Compressing OSM file..."
  osmium cat "$TEMP_DIR/renumbered.osm" -o "$COMPRESSED_OSM_PBF_FILE" --overwrite &>>"$LOG_FILE" && rm "$TEMP_DIR/renumbered.osm" &> /dev/null
  log_info "Done compressing OSM file."

  log_info "Done preparing OSM file. Compressed file: ${COMPRESSED_OSM_PBF_FILE}"
}
register "prepare" "osm" "Prepare OSM file" "prepare_osm_file"

prepare_osrm_data() {
  if [ ! -f "$COMPRESSED_OSM_PBF_FILE" ]; then
    log_error "${YELLOW}${COMPRESSED_OSM_PBF_FILE}${NC} file not found! Please prepare the OSM file first."
    exit 1
  fi

  log_info "Start preparing OSRM data..."
  mkdir -p "$OSRM_DIR"
  
  log_info "Extracting OSRM data..."
  docker run --rm \
      -v "$OSRM_DIR:/data" \
      -v "$COMPRESSED_OSM_PBF_FILE:/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" \
      "$OSRM_IMAGE" \
      osrm-extract -p "$OSRM_PROFILE" "/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" &>>"$LOG_FILE"

  log_info "Partitioning OSRM data..."
  docker run --rm \
      -v "$OSRM_DIR:/data" \
      -v "${COMPRESSED_OSM_PBF_FILE}:/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" \
      "$OSRM_IMAGE" \
      osrm-partition "/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" &>>"$LOG_FILE"

  log_info "Customizing OSRM data..."
  docker run --rm \
      -v "$OSRM_DIR:/data" \
      -v "${COMPRESSED_OSM_PBF_FILE}:/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" \
      "$OSRM_IMAGE" \
      osrm-customize "/data/$(basename "$COMPRESSED_OSM_PBF_FILE")" &>>"$LOG_FILE"

  log_info "Done preparing OSRM data."
  touch "$TEMP_DIR/${OSRM_CONTAINER_NAME}_prepared.tmp"
}
register "prepare" "osrm" "Prepare OSRM data" "prepare_osrm_data"

prepare_photon_data() {
  if [[ ! -f "$PHOTON_JAR_FILE" ]]; then
    log_error "${YELLOW}${PHOTON_JAR_FILE}${NC} file not found!"
    exit 1
  fi

  if [[ ! -f "$TEMP_DIR/${NOMINATIM_CONTAINER_NAME}_ready.tmp" ]]; then
    log_error "Nominatim service is not ready! Please start the Nominatim service first."
    exit 1
  fi

  log_info "Start preparing Photon data..."

  java -jar ${PHOTON_JAR_FILE} \
    -nominatim-import \
    -data-dir $PHOTON_DATA_DIR \
    -port ${NOMINATIM_DB_PORT} \
    -password ${NOMINATIM_PASSWORD} \
    -languages ru,kk &>>"$LOG_FILE"

  log_info "Done preparing Photon data."
  touch "$TEMP_DIR/${PHOTON_SERVICE_NAME}_prepared.tmp"
}
register "prepare" "photon" "Prepare Photon data" "prepare_photon_data"
