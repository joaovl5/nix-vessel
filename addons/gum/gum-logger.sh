level_to_gum() {
  case "$1" in
  error) echo "error" ;;
  warn) echo "warn" ;;
  info) echo "info" ;;
  debug) echo "debug" ;;
  trace) echo "debug" ;;

  *) return 1 ;;
  esac
}

if ! GUM_LEVEL=$(level_to_gum "$LOG_LEVEL"); then
  echo "Invalid log level: $LOG_LEVEL" >&2
  exit 2
fi

# these envvars are set via nix
gum log \
  --time "$GUM_LOG_TIME" \
  --prefix "$GUM_LOG_PREFIX" \
  --level "$GUM_LEVEL" \
  "$LOG_MESSAGE"
