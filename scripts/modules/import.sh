import_osm_to_postgis() {
  if [ ! -f "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_ready.tmp" ]; then
    log_error "PostGIS database is not started! Please start the PostGIS database first."
    exit 1
  fi

  if [ ! -f "$COMPRESSED_OSM_PBF_FILE" ]; then
    log_error "${YELLOW}${COMPRESSED_OSM_PBF_FILE}${NC} file not found! Please prepare the OSM file first."
    exit 1
  fi

  if [[ -z "$MAPPING_FILE" || ! -f "$MAPPING_FILE" ]]; then
    log_error "Mapping file not found: ${MAPPING_FILE}"
    exit 1
  fi

  log_info "Starting to import OSM data to PostGIS container..."

  imposm import \
        -mapping "$MAPPING_FILE" \
        -read "$COMPRESSED_OSM_PBF_FILE" \
        -write \
        -connection "$POSTGIS_URL" \
        -overwritecache \
        -deployproduction &>>"$LOG_FILE"

  log_info "OSM data imported to PostGIS container."

  if [[ ! -z "${POSTGIS_POST_SCRIPTS_DIR:-}" || -d "$POSTGIS_POST_SCRIPTS_DIR" ]]; then
    local sql_scripts=("$POSTGIS_POST_SCRIPTS_DIR"/*.sql)

    if (( ${#sql_scripts[@]} > 0 )); then
      log_info "Found ${#sql_scripts[@]} SQL scripts in ${POSTGIS_POST_SCRIPTS_DIR}. Start executing them..."
      
      for sql_script in "${sql_scripts[@]}"; do
        docker exec -i "$POSTGIS_CONTAINER_NAME" psql -p 5432 -U "$POSTGIS_USER" -d "$POSTGIS_DB" -v ON_ERROR_STOP=1 < "$sql_script" &>>"$LOG_FILE"
      done

      log_info "All SQL scripts executed successfully." 0
    fi
  fi

  log_info "PostGIS service is successfully imported."
  touch "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_imported.tmp"
}
register "import" "osm" "Import OSM data to PostGIS container" "import_osm_to_postgis"
