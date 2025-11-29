#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_log() {
    local level="$1"
    local color="$2"
    local msg="$3"
    local module="$4"

    local ts
    ts=$(date +"%Y-%m-%d %H:%M:%S")

    printf "${color} %-5s | %-19s | %-15s | %b${NC}\n" "$level" "$ts" "$module" "$msg"
   
    printf " %-5s | %-19s | %-15s | %s\n" "$level" "$ts" "$module" "$msg" >> "$LOG_FILE"
}

log_info() {
    _log "INFO" "$GREEN" "$1" "${3:-$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")}"
}

log_warn() {
    _log "WARN" "$YELLOW" "$1" "${3:-$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")}" 
}

log_error() {
    _log "ERROR" "$RED" "$1" "${3:-$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")}" 
}

log_debug() {
    _log "DEBUG" "$BLUE" "$1" "${3:-$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")}"
}

handle_error() {
    local exit_code=$?
    local line_no=$1
    local file=$2
    local func="${FUNCNAME[1]:-main}"
    local cmd="${BASH_COMMAND:-}"

    log_error "Exited with error. File: $file, Line: $line_no, Function: $func, Command: $cmd, Exit Code: $exit_code" "$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")"

    log_error "Backtrace:" "$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")"
    local i=1
    while [ $i -lt ${#FUNCNAME[@]} ]; do
        log_error "  ${FUNCNAME[$i]}() в ${BASH_SOURCE[$i]}:${BASH_LINENO[$((i-1))]}" "$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")"
        ((i++))
    done

    log_warn "See $LOG_FILE for more details." "$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")"

    exit $exit_code
}

help() {
    echo -e "${GREEN}Usage: $(basename "$0") ${BLUE}<command>${NC}  ${YELLOW}<action>${NC}"
    echo
    echo -e "${YELLOW}Available commands:${NC}"
    echo

    local max_cmd=7 max_action=6 max_hint=4
    for (( i=0; i<${#commands[@]}; i++ )); do
        (( ${#commands[$i]} > max_cmd )) && max_cmd=${#commands[$i]}
        (( ${#actions[$i]} > max_action )) && max_action=${#actions[$i]}
        (( ${#hints[$i]} > max_hint )) && max_hint=${#hints[$i]}
    done

    printf "%-${max_cmd}s | %-${max_action}s | %-${max_hint}s\n" "Command" "Action" "Hint"

    printf "%-${max_cmd}s-+-%-${max_action}s-+-%-${max_hint}s\n" \
        "$(printf '─%.0s' $(seq 1 $max_cmd))" \
        "$(printf '─%.0s' $(seq 1 $max_action))" \
        "$(printf '─%.0s' $(seq 1 $max_hint))"

    for (( i=0; i<${#commands[@]}; i++ )); do
        printf "${BLUE}%-${max_cmd}s${NC} | ${YELLOW}%-${max_action}s${NC} | %-${max_hint}s\n" \
            "${commands[$i]}" "${actions[$i]}" "${hints[$i]}"
    done
}


