{
  pkgs,
  fancy,
  ...
}: let
  inherit (pkgs) lib;
  inherit
    (lib)
    types
    ;
  inherit
    (fancy)
    w-k-x
    ;

  _modules = rec {
    mod-eval = modules: special-args: extra-opts:
      lib.evalModules ({
          specialArgs = special-args;
          inherit modules;
        }
        // extra-opts);

    when = lib.mkIf;
    merge = lib.mkMerge;
    force = lib.mkForce;
    override = lib.mkOverride;
    default = lib.mkDefault;
    do-order = lib.mkOrder;
    do-before = lib.mkBefore;
    do-after = lib.mkAfter;
    do-assert = lib.mkAssert;
    opt = t: lib.mkOption {type = t;};

    # these become functions that take an existing option
    # definition and update it to include a new field
    w-def = w-k-x "default";
    w-def-txt = w-k-x "defaultText";
    w-desc = w-k-x "description";
    w-example = w-k-x "example";
    w-apply = w-k-x "apply";
    # these we can already mark the next arg since they curry
    w-internal = w-k-x "internal" true;
    w-hidden = w-k-x "visible" false;
    w-read-only = w-k-x "readOnly" true;
  };

  _types = {
    inherit
      (types)
      port
      str
      float
      number
      int
      bool
      anything
      unspecified
      raw
      lines
      package
      enum
      ;

    bool-or = types.boolByOr;
    path-store = types.pathInStore;
    path-external = types.externalPath;
    path-relative = types.pathWith {absolute = false;};
    path-absolute = types.pathWith {absolute = true;};

    # "modifiers"
    list = types.listOf;
    attrs = types.attrsOf;
    attrs-lazy = types.lazyAttrsOf;
    or-null = types.nullOr;
    or-either = types.either;
    one-of = types.oneOf;

    # other
    mod-sub = types.submodule;
    mod-deferred = types.deferredModule;
  };
in
  _modules
  // _types
