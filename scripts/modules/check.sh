chech_dependencies() {
  log_info "Checking dependencies..."

  local missing_deps=()
  local required_deps=("osmfilter" "osmium" "imposm" "docker" "java")
    
  for dep in "${required_deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        missing_deps+=("$dep")
    fi
  done
    
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_warn "Missing dependencies: ${missing_deps[*]}. Please install them and try again."
    exit 1
  fi
    
  # Check Docker daemon
  if ! docker info &>/dev/null; then
    log_warn "Docker daemon is not running. Please start it and try again."
    exit 1
  fi
    
  log_info "All dependencies satisfied"

  local images=("$POSTGIS_IMAGE" "$MARTIN_IMAGE" "$OSRM_IMAGE" "$NOMINATIM_IMAGE" "$MAPUTNIK_IMAGE" "ubuntu:latest")
  log_info "Checking docker images..."
  for image in "${images[@]}"; do
    if ! docker image inspect "$image" &>/dev/null; then
      log_warn "Docker image $image not found. Trying to pull..."
      
      docker pull "$image" 2>&1 | tee -a "$LOG_FILE"
    else
      log_info "Docker image $image found."
    fi
  done

} 
register "check" "all" "Check all necessary dependencies" "chech_dependencies"

check_services() {
  log_info "Checking services..."

  if [[ ! -f "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_ready.tmp" || ! -f "$TEMP_DIR/${POSTGIS_CONTAINER_NAME}_imported.tmp" ]]; then
    log_warn "PostGIS database is not ready! Not Pass..."
  else
    log_info "PostGIS database is ready. Pass... \t${POSTGIS_URL}"
  fi

  if [[ ! -f "$TEMP_DIR/${MARTIN_CONTAINER_NAME}_ready.tmp" ]]; then
    log_warn "Martin service is not ready! Not Pass..."
  else
    log_info "Martin service is ready. Pass... \thttp://${HOST_IP}:${MARTIN_PORT}/"
  fi
  
  if [[ ! -f "$TEMP_DIR/${OSRM_CONTAINER_NAME}_ready.tmp" ]]; then
    log_warn "OSRM service is not ready! Not Pass..."
  else
    log_info "OSRM service is ready. Pass... \thttp://${HOST_IP}:${OSRM_PORT}/"
  fi

  if [[ ! -f "$TEMP_DIR/${NOMINATIM_CONTAINER_NAME}_ready.tmp" ]]; then
    log_warn "Nominatim service is not ready! Not Pass..."
  else
    log_info "Nominatim service is ready. Pass... \thttp://${HOST_IP}:${NOMINATIM_REVERSE_PORT}/"
  fi

  if [[ ! -f "$TEMP_DIR/${PHOTON_SERVICE_NAME}_ready.tmp" ]]; then
    log_warn "Photon service is not ready! Not Pass..."
  else
    log_info "Photon service is ready. Pass... \thttp://${HOST_IP}:${PHOTON_PORT}/"
  fi 

  if [[ ! -f "$TEMP_DIR/${MAPUTNIK_CONTAINER_NAME}_ready.tmp" ]]; then
    log_warn "Maputnik service is not ready! Not Pass..."
  else
    log_info "Maputnik service is ready. Pass... \thttp://${HOST_IP}:${MAPUTNIK_PORT}/"
  fi 
}
register "check" "services" "Check all necessary services" "check_services"

