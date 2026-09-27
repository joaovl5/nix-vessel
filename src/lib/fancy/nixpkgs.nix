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
    err
    ;

  _modules = rec {
    mod-eval = modules: special-args: extra-opts:
      lib.evalModules ({
          specialArgs = special-args;
          inherit modules;
        }
        // extra-opts);
    mod-bake = module-args: bake-args: let
      # allow string or lists in path and auto-handle them
      namespace =
        bake-args.ns or (
          err.required-k "ns" "Use `mod-ns` for setting the namespace!"
        );
      _namespace = let
        t = builtins.typeOf namespace;
      in
        if t == "list"
        then namespace
        else if t == "string"
        then [namespace]
        else err.unexpected-t' t "string or list";
      _get-namespace = _attrsets.get-path _namespace;
      _set-namespace = _attrsets.set-path _namespace;
      _lambda-args = {
        cfg = module-args.config |> _get-namespace;
      };
      # recurse to resolve:
      # - lambdas, by applying `lambda-args`
      # - lists, by applying `merge` (if `lists-ok` is true)
      #
      # `x` is reduced into attrset
      _handle-arg = lists-ok: x: let
        t = builtins.typeOf x;
      in
        if t == "set"
        then x
        else if t == "lambda"
        then _handle-arg lists-ok (x _lambda-args)
        else if t == "list" && lists-ok
        then merge (map (_handle-arg lists-ok) x)
        else
          err.unexpected-t' t (
            if lists-ok
            then "lambda, list, or attrset"
            else "lambda or attrset"
          );

      options = bake-args.opts or {} |> _handle-arg false |> _set-namespace;
      config = bake-args.cfg or {} |> _handle-arg true;
      extra = bake-args.extra or {} |> _handle-arg false;
    in
      extra # we reject deep merges to avoid spooky behavior
      // {inherit options config;};
    mod-ns = ns: {inherit ns;};
    w-opts = w-k-x "opts";
    w-cfg = w-k-x "cfg";
    w-extra = w-k-x "extra";
    w-freeform = w-k-x "freeformType";

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

    json-format = pkgs.formats.json {};

    bool-or = types.boolByOr;
    path-store = types.pathInStore;
    path-external = types.externalPath;
    path-relative = types.pathWith {absolute = false;};
    path-absolute = types.pathWith {absolute = true;};

    # "modifiers"
    list = types.listOf;
    attrs = types.attrsOf;
    attrs-any = types.attrs;
    attrs-lazy = types.lazyAttrsOf;
    or-null = types.nullOr;
    or-either = types.either;
    one-of = types.oneOf;

    # other
    mod-sub = types.submodule;
    mod-deferred = types.deferredModule;
  };

  _attrsets = {
    get-path = lib.getAttrFromPath;
    set-path = lib.setAttrByPath;
    deep-merge = lib.attrsets.recursiveUpdate;
    when-attrs = lib.optionalAttrs;
  };

  _lists = {
    sort-by = lib.sortOn;
    dedupe = lib.unique;
    inherit (lib) flatten;
  };

  _meta = {
    default-prio = lib.meta.defaultPriority;
  };

  _strings = {
    when-str = lib.optionalString;
    merge-lines = lib.concatLines;
    inherit (lib) join;
  };

  _drv = {
    mk-search-path = lib.makeSearchPath;
  };

  # helpers (built ontop the other helpers, 2nd order helpers?)
  _helpers = rec {
    _w-toggle = _types.bool |> _modules.opt;
    w-toggle = _w-toggle |> _modules.w-def true;
    w-toggle' = _w-toggle |> _modules.w-def false;
  };
in
  _modules
  // _types
  // _attrsets
  // _lists
  // _meta
  // _strings
  // _helpers
  // _drv
