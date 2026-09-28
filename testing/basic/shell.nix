{pkgs ? import <nixpkgs> {}}:
(import ../../src).mk-shell {
  inherit pkgs;
  inputs = {
    treefmt =
      builtins.fetchTarball
      "https://github.com/numtide/treefmt-nix/archive/refs/heads/master.tar.gz"
      |> import;
  };
  addons = [
    "gum"
    "treefmt"
  ];
  modules = [
    {
      packages = with pkgs; [
        ruby
      ];

      shell-hook =
        # bash
        ''
          echo "Hello $(whoami)!"
        '';

      treefmt = {
        root-file = "shell.nix";
        config = {
          programs.rumdl-check.enable = true;
        };
      };

      vessel = {
        log.level = "debug";
      };
    }
  ];
}
