LEVEL=${1-}
MESSAGE=${2-}
CONFIGURED_LEVEL=${NIX_VESSEL_LOG_LEVEL:-info}

level_number() {
  case "$1" in
  error) echo 0 ;;
  warn) echo 1 ;;
  info) echo 2 ;;
  debug) echo 3 ;;
  trace) echo 4 ;;

  *) return 1 ;;
  esac
}

print_usage() {
  echo "Usage: $0 <error|warn|info|debug|trace> <message>" >&2
}

if [[ ${NIX_VESSEL_DO_LOGS:-false} != "true" ]]; then
  exit 0
fi

if (($# != 2)); then
  print_usage
  exit 2
fi

if ! LEVEL_NUM=$(level_number "$LEVEL"); then
  echo "Invalid message level: $LEVEL" >&2
  print_usage
  exit 2
fi

if ! CONFIGURED_LEVEL_NUM=$(level_number "$CONFIGURED_LEVEL"); then
  echo "Invalid log level: $CONFIGURED_LEVEL" >&2
  echo "This log level is set by the envvar NIX_VESSEL_LOG_LEVEL" >&2
  print_usage
  exit 2
fi

if ((LEVEL_NUM <= CONFIGURED_LEVEL_NUM)); then
  # this function will be defined in nix
  call_logger "$LEVEL" "$MESSAGE"
fi
