# draft for stuff nevermind this file pls
{
  fancy,
  pkgs,
  ...
} @ args: let
  inherit
    (fancy)
    # keep-sorted start
    mod-bake
    mod-ns
    w-cfg
    w-def
    w-desc
    w-opts
    w-toggle
    w-toggle'
    when
    # keep-sorted end
    ;
in
  # sample lazygit thing
  mod-bake args (
    mod-ns ["programs" "lazygit"]
    |> w-opts ({cfg, ...}: {
      enable =
        w-toggle
        |> w-desc "Enable Lazygit.";
      crazy-mode =
        w-toggle'
        |> w-desc "Toggle crazy things, false by default.";

      add-clippy =
        w-toggle'
        # defaults to true if crazy-mode is active
        |> w-def cfg.crazy-mode
        # this plugin obviously does not exist
        # that does not mean I cannot dream.
        |> w-desc "Add the famous Clippy plugin to Lazygit.";
    })
    |> w-cfg ({cfg, ...}:
      # automatically have a "merge" (lib.mkMerge) if list is detected
      [
        (when cfg.enable {
          packages = [pkgs.lazygit];
        })
        (when (cfg.add-clippy && cfg.enable) {
          # this is totally how this works!
          file."~/.config/lazygit/clippy.exe" = pkgs.clippy;
        })
      ])
  )
