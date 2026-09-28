{
  fancy,
  pkgs,
  ...
} @ args: let
  inherit
    (fancy)
    # keep-sorted start
    dedupe
    do-at
    elem
    filter
    flatten
    lines
    list
    merge-lines
    mk-search-path
    mod-bake
    mod-ns
    opt
    package
    w-cfg
    w-def
    w-desc
    w-imports
    w-opts
    w-toggle
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
    })
    |> w-imports [
      ./logging
    ]
    |> w-cfg ({cfg, ...}: {
      shell-hook =
        [
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
        |> do-at 2;
    })
  )
