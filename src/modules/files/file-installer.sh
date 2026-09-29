# some envvars are handled via nix
#
if ! git rev-parse --git-dir &>/dev/null; then
  log error "files declared with 'file.<path>' currently are not supported outside of a git repository!"
  exit 2
fi

SOURCE_PATH="$1"
TARGET_PATH="$2"
FORCE_WRITE="$3"
GIT_WC=$(git rev-parse --show-toplevel)
FULL_TARGET_PATH="${GIT_WC}/${TARGET_PATH}"

if LINK_TARGET=$(readlink "$FULL_TARGET_PATH") &&
  [[ "$LINK_TARGET" == "$SOURCE_PATH" ]]; then
  log debug "file already installed and up-to-date"
  exit 0
fi

# unlink if it's a link
[ -L "$FULL_TARGET_PATH" ] && unlink "$FULL_TARGET_PATH"

# if file still exists (not a link, existing config)
if [ -e "$FULL_TARGET_PATH" ] &&
  [[ "$FORCE_WRITE" != "true" ]]; then
  log warn "refusing to install file in '${TARGET_PATH}', there's an existing file there! to force an existing file to be overwritten via nix, set the 'force' option."
  exit 2
fi

log trace "$(cp -v -f "$SOURCE_PATH" "$FULL_TARGET_PATH")"
