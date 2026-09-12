{fancy, ...}: let
  inherit
    (fancy)
    opt
    w-def
    w-desc
    list
    package
    lines
    ;
in {
  options = {
    packages =
      package
      |> list
      |> opt
      |> w-def {}
      |> w-desc "Packages to include in the dev shell.";
    shell-hook =
      lines
      |> opt
      |> w-def ""
      |> w-desc "Bash lines appended to shell hook.";
  };
}
