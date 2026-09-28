# some envvars are handled via nix

if ! git rev-parse --git-dir &>/dev/null; then
  log warn ".git not found, skipping git hooks installation"
  exit
fi

# CFG_FILE=... (set by nix, a store path)
# ADD_GC_ROOT=... (set by nix, true/false value)
CFG_PATH="prek.toml"
GIT_WC=$(git rev-parse --show-toplevel)
FULL_CFG_PATH="${GIT_WC}/${CFG_PATH}"

# this matters because some setups might have a global hooksPath which
# might prevent hooks execution if we don't explicitly add it to the
# local configs as well
set_hooks_path() {
  COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
  COMMON_DIR=${COMMON_DIR#"$GIT_WC"/}
  HOOKS_PATH="$COMMON_DIR/hooks"
  git config \
    --local \
    core.hooksPath \
    "$HOOKS_PATH"
  log debug "git's hooksPath was set to $HOOKS_PATH"
}

# we'll check several things before installing to avoid
# unnecessary I/O, which is bad esp. with watcher tools
# like lorri

# check if already linked to the expected store path
if LINK_TARGET=$(readlink "$FULL_CFG_PATH") &&
  [[ "$LINK_TARGET" == "$CFG_FILE" ]]; then
  log debug "git hooks already installed and up-to-date"
  exit 0
fi

# unlink if it's a link
[ -L "$FULL_CFG_PATH" ] && unlink "$FULL_CFG_PATH"

# if file still exists (not a link, existing config)
if [ -e "$FULL_CFG_PATH" ]; then
  log warn "refusing to install git hooks, there's an existing config at ${FULL_CFG_PATH}"
  log warn "please remove/migrate the existing file before proceeding"
  exit 2
fi

if [[ "$ADD_GC_ROOT" == "true" ]]; then
  nix-store \
    --add-root "$FULL_CFG_PATH" \
    --indirect \
    --realise "$CFG_FILE" \
    >/dev/null
  log debug "linked git hooks config via nix gc root"
else
  ln -sf \
    "$LINK_TARGET" \
    "$FULL_CFG_PATH"
  log debug "linked git hooks config via symlink (without nix gc root)"
fi

set_hooks_path
log trace "$(prek uninstall --all)"
log info "$(prek install --force)"
