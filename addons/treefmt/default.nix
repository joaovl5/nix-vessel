{
  fancy,
  pkgs,
  inputs,
  ...
} @ args: let
  inherit
    (fancy)
    mod-bake
    mod-ns
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
    w-toggle
    package
    err
    ;
in
  mod-bake args (mod-ns ["treefmt"]
    |> w-opts (_: {
      enable =
        w-toggle
        |> w-desc "Enable 'treefmt' addon for `treefmt-nix` integration";
      input-name =
        package
        |> opt
        |> w-def pkgs.gum
        |> w-desc "Name of the treefmt input for consumption";
      root-file =
        str
        |> opt
        |> w-def ".git/config"
        |> w-desc "Where to find the project root";
      config =
        {}
        |> w-freeform json-format.type
        |> mod-sub
        |> opt
        |> w-def {}
        |> w-desc "Configuration passed into `treefmt-nix`";
    })
    |> w-cfg ({cfg, ...}: (when cfg.enable (let
      treefmt-input =
        inputs.${
          cfg.input-name
        } or (err.required-k "inputs.${cfg.input-name}" ''
          Treefmt addon needs an input agreeing with its `input-name` option.
        '');
      treefmt-mod = treefmt-input pkgs ({
          projectRootFile = cfg.root-file;
        }
        // cfg.config);
      treefmt-wrapper = treefmt-mod.config.build.wrapper;
    in {
      packages = [
        treefmt-wrapper
      ];
    }))))
