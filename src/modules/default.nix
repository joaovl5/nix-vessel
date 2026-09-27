{
  fancy,
  pkgs,
  ...
} @ args: let
  inherit
    (fancy)
    # keep-sorted start
    bool
    dedupe
    do-before
    elem
    enum
    filter
    flatten
    get-env
    join
    lines
    list
    merge-lines
    mk-search-path
    mod-bake
    mod-ns
    opt
    package
    raw
    w-cfg
    w-def
    w-desc
    w-opts
    w-toggle
    w-toggle'
    when-attrs
    when-str
    # keep-sorted end
    ;

  shell-outputs = [
    "out"
    "bin"
    "lib"
    "dev"
    "include"
  ];
  # preserve "meta" for some output in a derivation
  with-meta = drv: out:
    drv.${out} // when-attrs (drv ? "meta") {inherit (drv) meta;};

  # some packages do not offer their outputs in the same places,
  # so we need this function; this matters in e.g. collection of
  # man-pages, which may not be in the same output as the main
  # package (OpenSSL for instance)
  #
  # this function was adapted from one in devenv's tree
  drv-paths = drv: let
    outputs =
      if drv.outputSpecified or false || !(drv ? outputs)
      then [drv]
      else let
        outs-available =
          ((drv.meta.outputsToInstall or []) ++ shell-outputs)
          |> dedupe
          |> filter (x: elem x drv.outputs)
          |> map (with-meta drv);
      in
        if outs-available == []
        then [drv]
        else outs-available;
    # also grab transitive deps for python if they exist
    py-deps = drv.requiredPythonModules or [];
  in
    outputs ++ py-deps;
in
  mod-bake args (
    mod-ns []
    |> w-opts (_: {
      packages =
        package
        |> list
        |> opt
        |> w-def {}
        |> w-desc "Packages to include in the dev shell.";
      shell-hook =
        lines
        |> opt
        |> w-def ""
        |> w-desc "Bash lines appended to shell hook.";
      # some QoL improvements to shells
      fixes = {
        man-pages =
          w-toggle
          |> w-desc "Symlink the man-pages from shell packages";
        locales =
          w-toggle
          |> w-desc "Symlink locales for non-NixOS distros";
      };
      # nix-vessel options
      vessel = {
        log = {
          level =
            enum [
              "error"
              "warn"
              "info"
              "debug"
              "trace"
            ]
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
          logger =
            raw
            |> opt
            |> w-def
            (log-level: message: let
              msg-prefixes = {
                "error" = "ERROR ";
                "warn" = "WARN  ";
                "info" = "INFO  ";
                "debug" = "DEBUG ";
                "trace" = "TRACE ";
              };
              prefix = "| " + msg-prefixes.${log-level} + " | ";
            in
              # bash
              "echo \"${prefix}${message}\"")
            |> w-desc
            ''
              Hook function for printing a logging command, used by `shell-hook`.
              Due to Nixpkgs' module system limitations, this is not type-checked,
              since it deals with a function, therefore it's best to avoid tweaking
              this option unless you know what you're doing.

              The expected function signature is:

              ```
              logger  :: log-level: String -> message: String -> out: String
              ```

              Where the aliases refer to:
              - `log-level` - message log-level
              - `message` - message to be logged
              - `out` - the string to be concatenated in `shell-hook`
            '';
        };
      };
    })
    |> w-cfg ({cfg, ...}: let
      _log-level-env = get-env "NIX_VESSEL_LOG_LEVEL";
      _log-non-interactive-env = get-env "NIX_VESSEL_LOG_NONINTERACTIVE";
      log-non-interactive =
        if _log-non-interactive-env != ""
        then _log-non-interactive-env
        else cfg.vessel.log.non-interactive;
      log-level =
        if _log-level-env != ""
        then _log-level-env
        else cfg.vessel.log.level;
      log-level-values = {
        "error" = 0;
        "warn" = 1;
        "info" = 2;
        "debug" = 3;
        "trace" = 4;
      };
      # `true` if log level `a` matches at least `b`
      _lvl-compare = b: a:
        log-level-values.${a} >= log-level-values.${b};
      # return a list of all log-levels at least as high as `lvl`
      # yes, this is a naive way for doing this check but i'm not
      # going to write a better bash function right now, this can be
      # done later
      _accepted-levels = lvl:
        ["error" "warn" "info" "debug" "trace"]
        |> filter (_lvl-compare lvl);
      _cond-one-level = lvl: "[ $NIX_VESSEL_LOG_LEVEL = \"${lvl}\" ]";
      _cond-levels = lvl:
        _accepted-levels lvl
        |> map _cond-one-level
        |> join " || ";
      # build an "if" for some log level
      _test-log-level = expected-lvl: body:
      # bash
      ''
        if ${_cond-levels expected-lvl}; then
          ${body}
        fi
      '';
      # wrap so it only executes in interactive shells
      _wrap-log-interactive = body:
      # bash
      ''
        if [[ $- == *i* ||
              "${"$"}{NIX_VESSEL_LOG_NONINTERACTIVE:-false}" == true ]]; then
          ${body}
        fi
      '';
      mk-log = lvl: msg:
        cfg.vessel.hooks.logger lvl msg
        |> _test-log-level lvl
        |> _wrap-log-interactive;
    in {
      shell-hook =
        [
          ### Handle logs:
          # bash
          ''
            NIX_VESSEL_LOG_LEVEL=${log-level}
            NIX_VESSEL_LOG_NONINTERACTIVE=${log-non-interactive}
          ''
          (when-str (log-level == "trace") "set -x")
          (mk-log "info" "Starting nix shell...")

          ### Handle `fixes` namespace:
          (when-str (cfg.fixes.locales
              && pkgs.stdenv.hostPlatform.isLinux
              && (pkgs.glibcLocalesUtf8 != null))
            # bash
            ''
              if [ -z "${"$"}{LOCALE_ARCHIVE-}" ]; then
                export LOCALE_ARCHIVE=${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive
              fi
            '')
          (when-str cfg.fixes.man-pages
            (let
              man-path =
                map drv-paths cfg.packages
                |> flatten
                |> mk-search-path "share/man";
            in
              # bash
              "export MANPATH=\"${man-path}:\${MANPATH:+$MANPATH:}\""))
        ]
        |> filter (x: x != "")
        |> merge-lines
        |> do-before;
    })
  )
