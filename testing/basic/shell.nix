{pkgs ? import <nixpkgs> {}}:
import ../../src {
  inherit pkgs;
  addons = ["gum"];
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

      vessel = {
        log.level = "debug";
      };
    }
  ];
}
