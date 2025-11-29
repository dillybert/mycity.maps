#!/bin/bash

declare -a commands
declare -a actions
declare -a hints
declare -a functions

register () {
  commands+=("$1")
  actions+=("$2")
  hints+=("$3")
  functions+=("$4")
}

cli() {
  cmd="${1:-}"; shift || true
  action="${1:-}"; shift || true
  valid_command=false
  valid_action=false

  for (( i = 0; i < ${#commands[@]}; ++i )); do
    if [ "${cmd}" = "${commands[$i]}" ]; then
      valid_command=true
      if [ "${action}" = "${actions[$i]}" ]; then
        valid_action=true
        "${functions[$i]}" "$@"
        exit $?
      fi
    fi
  done

  [ -z "${cmd}" ] || [ "$valid_command" = true ] || echo -e "${RED}Invalid command:${NC} ${YELLOW}$cmd${NC}"
  [ -z "${action}" ] || [ "$valid_action" = true ] || echo -e "${RED}Invalid action for command ${NC}${YELLOW}$cmd${NC}: ${YELLOW}$action${NC}"
  help

  exit 1
}

