_args: let
  args = _args // {fancy = out;};
  nixpkgs = import ./nixpkgs.nix args;
  out =
    (import ./misc.nix args)
    // nixpkgs;
in
  out
