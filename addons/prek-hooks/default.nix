# Huge thanks to `cachix/git-hooks.nix` which was used for both
# the initial inspiration and adaptation for some of the source
# in this file.
{
  fancy,
  pkgs,
  ...
} @ args: let
  inherit
    (fancy)
    mod-bake
    mod-ns
    read-file
    mk-shell-script
    get-exe
    filter
    write-toml
    str-from-bool
    merge-lines
    do-before
    mod-sub
    opt
    w-cfg
    w-freeform
    json-format
    str
    w-def
    w-desc
    when
    w-opts
    package
    w-toggle
    when-str
    err
    ;
in
  mod-bake args (mod-ns ["git" "hooks"]
    |> w-opts (_: {
      enable =
        w-toggle
        |> w-desc "Enable 'git-hooks' addon for configuring git hooks with `prek`";
      add-gc-root =
        w-toggle
        |> w-desc "Add a Nix GC root to the generated file for avoiding garbage-collection";
      package =
        package
        |> opt
        |> w-def pkgs.prek
        |> w-desc "Package for `prek`";
      git-package =
        package
        |> opt
        |> w-def pkgs.git
        |> w-desc "Package for git, used for internal scripts";
      config =
        {}
        |> w-freeform json-format.type
        |> mod-sub
        |> opt
        |> w-def {}
        |> w-desc "Configuration passed into the pre-commit tool";
    })
    |> w-cfg ({cfg, ...}: (when cfg.enable (let
      raw-config = {
        "repos" = [
          {
            repo = "builtin";
            hooks = [
              {id = "trailing-whitespace";}
              {id = "end-of-file-fixer";}
              {id = "check-added-large-files";}
            ];
          }
        ];
      };
      config-file = write-toml {
        filename = "prek.toml";
        input-content = raw-config;
        # for triggering updates with prek
        args.extra.build-inputs = [cfg.package];
      };
      install-script = mk-shell-script {
        name = "install_prek_hooks";
        text = read-file ./install-script.sh;
        runtime-deps = [cfg.git-package];
        runtime-envvars = {
          CFG_FILE = "${config-file}";
          ADD_GC_ROOT = str-from-bool cfg.add-gc-root;
        };
      };
    in {
      shell-hook = "${get-exe install-script}";
    }))))
