#!/bin/sh
# This is a very opinionated script for installing nix
# It installs:
# - nix with several experimental-features and substituters enabled
# - direnv
# - nix-direnv

set -eu

setup_nix() {
  printf "Setting up Nix...\n"

  NIX_DAEMON_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

  if ! command -v nix >/dev/null 2>&1 &&
    [ -r "$NIX_DAEMON_PROFILE"]; then
    . "$NIX_DAEMON_PROFILE"
  fi

  if command -v nix >/dev/null 2>&1; then
    printf "Skipping Nix installation since Nix is already installed\n"
  else

    INSTALLER_URL="https://artifacts.nixos.org/nix-installer"
    INSTALLER=$(mktemp)

    trap 'rm -f "$INSTALLER"' 0
    trap 'exit 1' HUP INT TERM

    curl -sSfL "$INSTALLER_URL" -o "$INSTALLER"

    EXTRA_CONF='experimental-features = nix-command flakes pipe-operators blake3-hashes ca-derivations dynamic-derivations external-builders fetch-closure git-hashing
substituters = https://cache.nixos.org https://nix-community.cachix.org https://cache.numtide.com
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
warn-dirty = false'

    sh "$INSTALLER" install \
      --no-confirm \
      --extra-conf "$EXTRA_CONF"

    rm -f "$INSTALLER"
    trap - 0 HUP INT TERM

    if [ ! -r "$NIX_DAEMON_PROFILE" ]; then
      printf "Nix installed, but its profile script wasn't found.\n" >&2
      return 1
    fi

    # source newly-installed nix things in the current environment
    . "$NIX_DAEMON_PROFILE"
  fi

  # deal with macos-specific things
  case $(uname -s) in
  Darwin)
    if [ -x "$HOME/.nix-profile/bin/bash" ]; then
      printf "Skipping bash installation since it already exists in the nix profile."
    else
      printf "Installing a current bash version for Nix...\n"
      nix profile add nixpkgs#bashInteractive
    fi
    ;;
  esac
}

has_direnv_hook() {
  case $1 in
  bash)
    bash -ic '
        declare -F _direnv_hook >/dev/null 2>&1 || exit 1

        if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
          for command in "${PROMPT_COMMAND[@]}"; do
            [[ $command == _direnv_hook ]] && exit 0
          done

          exit 1
        fi

        [[ ";${PROMPT_COMMAND:-};" == *";_direnv_hook;"* ]]
      ' </dev/null >/dev/null 2>&1
    ;;
  zsh)
    zsh -ic '
      (( $+functions[_direnv_hook] )) &&
        (( ${precmd_functions[(I)_direnv_hook]} )) &&
        (( ${chpwd_functions[(I)_direnv_hook]} ))
    ' </dev/null >/dev/null 2>&1
    ;;
  fish)
    fish -ic '
      functions --query __direnv_export_eval
      and functions --query __direnv_export_eval_2
    ' </dev/null >/dev/null 2>&1
    ;;
  *)
    return 1
    ;;
  esac
}

add_direnv_hook() {
  SHELL_NAME=$1
  CONFIG_FILE=$2
  HOOK=$3

  if ! command -v "$SHELL_NAME" >/dev/null 2>&1; then
    printf "Skipping %s: shell not found.\n" "$SHELL_NAME"
    return
  fi

  if has_direnv_hook "$SHELL_NAME"; then
    printf "Skipping %s: direnv already hooked.\n" "$SHELL_NAME"
    return
  fi

  mkdir -p "$(dirname "$CONFIG_FILE")"
  printf "\n%s\n" "$HOOK" >>"$CONFIG_FILE"
  printf "Added %s hook to %s.\n" "$SHELL_NAME" "$CONFIG_FILE"
}

add_direnv_cfg() {
  DIRENV_CFG_PATH=${XDG_CONFIG_HOME:-"$HOME/.config"}/direnv/direnv.toml
  DIRENV_CFG='[global]
  log_filter = "^$"
  log_format = "-"'

  mkdir -p "$(dirname "$DIRENV_CFG_PATH")"
  if ! [ -f "$DIRENV_CFG_PATH" ]; then
    printf "\n%s\n" "$DIRENV_CFG" >"$DIRENV_CFG_PATH"
  fi
}

setup_direnv() {
  printf "Setting up direnv...\n"

  nix profile add nixpkgs#direnv

  add_direnv_cfg

  add_direnv_hook \
    "bash" \
    "$HOME/.bashrc" \
    'eval "$(direnv hook bash)"'

  add_direnv_hook \
    "zsh" \
    "$HOME/.zshrc" \
    'eval "$(direnv hook zsh)"'

  add_direnv_hook \
    "fish" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish" \
    'direnv hook fish | source'
}

setup_nix_direnv() {
  printf "Setting up nix-direnv...\n"

  nix profile add nixpkgs#nix-direnv

  if [ -n "${DIRENV_CONFIG:-}" ]; then
    DIRENV_CONFIG_DIR=$DIRENV_CONFIG
  else
    DIRENV_CONFIG_DIR=${XDG_CONFIG_HOME:-"$HOME/.config"}/direnv
  fi

  CONFIG_FILE=$DIRENV_CONFIG_DIR/direnvrc
  NIX_DIRENV_SOURCE='source "$HOME/.nix-profile/share/nix-direnv/direnvrc"'

  mkdir -p "$(dirname "$CONFIG_FILE")"

  if [ -f "$CONFIG_FILE" ] &&
    grep -Fq 'nix-direnv/direnvrc' "$CONFIG_FILE"; then
    printf "Skipping nix-direnv: already configured in %s.\n" \
      "$CONFIG_FILE"
    return
  fi

  printf "\n%s\n" "$NIX_DIRENV_SOURCE" >>"$CONFIG_FILE"
  printf "Added nix-direnv configuration to %s.\n" "$CONFIG_FILE"
}

setup_nix
setup_direnv
setup_nix_direnv
