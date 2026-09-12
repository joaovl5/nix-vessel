{
  pkgs,
  modules ? [],
  ...
}: let
  inherit (pkgs) lib;

  fancy = import ./lib/fancy {inherit pkgs;};

  eval =
    fancy.mod-eval
    ([./modules] ++ modules)
    {inherit pkgs lib fancy;}
    {};

  cfg = eval.config;
in
  pkgs.mkShell {
    inherit (cfg) packages;
    shellHook = cfg.shell-hook;
  }
