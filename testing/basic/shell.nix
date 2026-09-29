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

      file."config.yml" = {
        type = "yaml";
        data = {
          a.b.c.d = [1 2 3 4];
          a.b.d.e = {
            foo = "bar";
            bar = "foo";
            yes = false;
            no = true;
          };
        };
      };

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
