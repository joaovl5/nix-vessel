# misc stuff!
_: rec {
  # null handler stuff
  # picks 'y' if 'x' is null
  or-y = y: x:
    if isNull x
    then y
    else x;
  # does the same but also more false-ish values
  or-y' = y: x:
    if
      (
        isNull x
        || x == ""
        || x == []
        || x == {}
      )
    then y
    else x;

  # helper for building helpers to update stuff
  # you'll likely benefit from seeing how it's used
  # instead of me trying to explain it
  #
  # see `nixpkgs.nix` for reference
  w-k-x = k: x: attrset:
    (attrset |> or-y {}) // {${k} = x;};

  # namespace for errors
  err = {
    unexpected-t = t: builtins.abort "Unexpected type: ${t}";
    unexpected-t' = t-bad: t-good:
      builtins.abort
      ''
        Unexpected type: ${t-bad}
        Type needed: ${t-good}
      '';
    required-k = k: info:
      builtins.abort
      ''
        Key '${k}' is required!

        ${info}
      '';
  };

  inherit
    (builtins)
    filter
    elem
    ;

  read-file = builtins.readFile;
  type-of = builtins.typeOf;
  get-env = builtins.getEnv;
  env-or = env-key: y: get-env env-key |> or-y' y;
  to-str = builtins.toString;
}
