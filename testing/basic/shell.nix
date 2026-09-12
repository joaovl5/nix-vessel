{pkgs ? import <nixpkgs> {}}:
import ../../src {
  inherit pkgs;
  modules = [
    {
      packages = [pkgs.hello];

      shell-hook =
        # bash
        ''
          echo "Hello $(whoami)!"
        '';
    }
  ];
}
