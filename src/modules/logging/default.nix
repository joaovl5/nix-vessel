{fancy, ...} @ args: let
  inherit
    (fancy)
    # keep-sorted start
    do-at
    enum
    env-or
    filter
    list
    merge-lines
    mk-shell-script
    mod-bake
    mod-ns
    opt
    package
    raw
    read-file
    str-from-bool
    type-of
    w-cfg
    w-def
    w-desc
    w-opts
    w-toggle'
    # keep-sorted end
    ;

  log-levels = ["error" "warn" "info" "debug" "trace"];
  _log-script = body:
  # bash
  ''
    call_logger() {
      LOG_LEVEL=''${1-}
      LOG_MESSAGE=''${2-}

      ${body}
    }

    ${read-file ./log-wrapper.sh}
  '';
in
  mod-bake args (
    mod-ns ["vessel"]
    |> w-opts {
      log = {
        level =
          log-levels
          |> enum
          |> opt
          |> w-def "info"
          |> w-desc
          ''
            Increases log level, with `trace` being of highest verbosity.
            The envvar `NIX_VESSEL_LOG_LEVEL` also is used and takes precedence.
          '';

        non-interactive =
          w-toggle'
          |> w-desc ''
            Whether to also record logs in non-interactive shells, disabled by default.

            This is to prevent duplicate shells (like `nom-shell` does) from making log
            records duplicated, but might be useful to disable in, for instance, cases
            running the shell in a CI/CD pipeline.
          '';
      };
      hooks = {
        logger-deps =
          package
          |> list
          |> opt
          |> w-def []
          |> w-desc "Dependencies for logger hook, if any.";
        logger =
          raw
          |> opt
          |> w-def
          # bash
          ''
            echo "$LOG_LEVEL : $LOG_MESSAGE"
          ''
          |> w-desc
          ''
            Hook for printing a logging command, used by `shell-hook`.
            This is not merge-able and only one value must be set, which
            should consist of a shell snippet for calling the log.

            The snippet will have the variables `$LOG_LEVEL` and
            `$LOG_MESSAGE` accessible, and it must assume the log
            level has already been checked (this will be put in a
            wrapper script which already checks the configured log
            level.)

            The `$LOG_LEVEL` value will be set according to the values
            of the log-levels enum type.
          '';
      };
    }
    |> w-cfg ({cfg, ...}: let
      _non-interactive =
        env-or "NIX_VESSEL_LOG_NONINTERACTIVE" cfg.log.non-interactive;
      _level =
        env-or "NIX_VESSEL_LOG_LEVEL" cfg.log.level;
      logger-script =
        cfg.hooks.logger
        |> _log-script
        |> (x:
          mk-shell-script {
            name = "log";
            text = x;
            bin = true;
            runtime-deps = cfg.hooks.logger-deps;
          });
    in {
      packages = [logger-script];
      shell-hook =
        [
          ### Handle logs:
          # we set these envvars again in case they're only set via options
          # and further scripts wanna use them

          # bash
          ''
            export NIX_VESSEL_LOG_LEVEL=${_level}
            export NIX_VESSEL_LOG_NONINTERACTIVE=${
              if type-of _non-interactive == "string"
              then _non-interactive
              else str-from-bool _non-interactive
            }
            # TODO: MOVE elsewhere
            # nom-shell (and its hooks) duplicate shells which causes weird issues
            # we generally do not want this to happen
            if ! [[ -t 1 ]]; then
              exit
            fi
            if [[ -t 1 || $NIX_VESSEL_LOG_NONINTERACTIVE == true ]]; then
              export NIX_VESSEL_DO_LOGS=true
            fi

            if [[ $NIX_VESSEL_LOG_LEVEL == "trace" ]]; then
              set -x
              log trace "Trace logs enabled!"
            fi

            log debug "Starting nix shell..."
          ''
        ]
        |> filter (x: x != "")
        |> merge-lines
        |> do-at 1;
    })
  )
