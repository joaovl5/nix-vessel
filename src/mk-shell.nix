{
  pkgs,
  modules ? [],
  addons ? [],
  inputs ? {},
  ...
}: let
  f = import ./lib/fancy {inherit pkgs;};

  mapped-addons = addons |> map (x: ../addons/${x});
  eval =
    f.mod-eval
    ([./modules] ++ modules ++ mapped-addons)
    {
      inherit
        pkgs
        inputs
        ;
      inherit (pkgs) lib;
      fancy = f;
    }
    {};

  cfg = eval.config;
in
  pkgs.mkShell {
    packages =
      cfg.packages
      |> f.sort-by (x: x.meta.priority or f.default-prio);
    inputsFrom = cfg.inputs-from;
    shellHook = cfg.shell-hook;
  }
