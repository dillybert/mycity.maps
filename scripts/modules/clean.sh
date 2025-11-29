clean_tmp() {
  log_info "Temporary files removed."
  rm -rf "$TEMP_DIR" &>> "$LOG_FILE"
}
register "clean" "tmp" "Remove temporary files" "clean_tmp"

clean_services() {
  log_info "Removing services..."

  docker rm -f "$POSTGIS_CONTAINER_NAME" "$MARTIN_CONTAINER_NAME" "$OSRM_CONTAINER_NAME" "$NOMINATIM_CONTAINER_NAME" "$MAPUTNIK_CONTAINER_NAME" &>> "$LOG_FILE"
  docker volume prune -f &>> "$LOG_FILE"
  
  if [ -f "$TEMP_DIR/${PHOTON_SERVICE_NAME}_ready.tmp" ]; then
    log_info "Stopping Photon service..."
    local pid=$(cat "$TEMP_DIR/${PHOTON_SERVICE_NAME}_ready.tmp")
    kill "$pid" &>> "$LOG_FILE"
  fi
  
  log_info "Services removed."
}
register "clean" "services" "Remove and clean all services" "clean_services"
