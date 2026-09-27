{
  fancy,
  pkgs,
  ...
} @ args: let
  inherit
    (fancy)
    mod-bake
    mod-ns
    force
    opt
    w-cfg
    str
    w-def
    w-desc
    when
    w-opts
    w-toggle
    package
    ;
in
  mod-bake args (mod-ns ["gum"]
    |> w-opts (_: {
      enable =
        w-toggle
        |> w-desc "Enable 'Gum' addon for prettier outputs";
      package =
        package
        |> opt
        |> w-def pkgs.gum
        |> w-desc "Gum package to use";
      log = {
        enable =
          w-toggle
          |> w-desc "Set logging hook to use Gum";
        time =
          str
          |> opt
          |> w-def "kitchen"
          |> w-desc ''
            Time format to use.

            Refer to Gum's CLI options for further reference.
          '';
        prefix =
          str
          |> opt
          |> w-def "nix-vessel"
          |> w-desc "Prefix for logged messages, omitted if empty.";
      };
    })
    |> w-cfg ({cfg, ...}: (when cfg.enable {
      packages = [cfg.package];
      vessel.hooks = {
        logger =
          when cfg.log.enable
          <| force
          <| (log-level: message: let
            # convert to gum's log level
            lvl-to-gum = {
              "error" = "error";
              "warn" = "warn";
              "info" = "info";
              "debug" = "debug";
              # there's no 'trace' equivalent in gum
              "trace" = "debug";
            };
            gum-lvl = lvl-to-gum.${log-level};
          in
            # bash
            ''
              gum log \
                --time ${cfg.log.time} \
                --prefix ${cfg.log.prefix} \
                --level ${gum-lvl} \
                "${message}"
            '');
      };
    })))
