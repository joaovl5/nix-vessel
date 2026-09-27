{pkgs ? import <nixpkgs> {}}: let
  f = import ../src/lib/fancy {inherit pkgs;};
  mock-prelude = {
    options = {
      packages = f.anything |> f.opt;
      file = f.attrs-any |> f.opt;
    };
  };
in
  f.mod-eval [
    mock-prelude
    ./draft.nix
    {programs.lazygit.crazy-mode = true;}
  ] {
    inherit pkgs;
    fancy = f;
  } {}
