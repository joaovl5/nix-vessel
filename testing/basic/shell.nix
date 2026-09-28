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
        # TODO: FIGURE OUT WHY FIRST LOG IS BEING REPEATED AND FIRST TIME WITH NO COLOR
        #
        # TODO: FIGURE OUT WHY ONLY *THIS* IS BEING REPEATED AT EXIT AND NOT OTHER LOGS
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
