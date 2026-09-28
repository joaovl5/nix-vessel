# `nix-vessel`

This is a library for constructing Nix dev-shells that uses a module system to allow for greater flexibility, i.e. no more `mkShell`.

*In some ways,* this might be seen as an alternative to projects such as devenv.sh, devbox, flox, and others. `nix-vessel` differs in that it tries to be as minimal as possible while providing a solid foundation, sticking to Nix (no JSON/YAML or similar shenanigans), and having minimum footprint.

To that end, the core of the library offers only the basics, and any additional things ("add-ons" described down below) are opt-in behavior. This means only what is needed will be imported and evaluated by Nix.

**IMPORTANT:** This library requires the Nix feature `pipe-operators` to be enabled.

## Feature Comparison

<!-- TODO -->

## Add-ons

These are pieces of additional/alternative functionality for the `nix-vessel` shell - they are not included in the base library to adhere to the minimal ideals of the project.

For including an addon, just append its name as a string to the `addons` parameter when invoking `nix-vessel`:

```nix
{

  inputs = { /* ... */ };
  addons = [
    "gum" # see what this does in the list below
  ];
}
```

Some outputs might also require inputs, like `treefmt`, which can be customized via its `treefmt.input-name` option.

This is the list of addons currently available:

| Addon Name    | What it does              | Requirements/Conflicts |
|---------------|---------------------------|------------------------|
| `gum`         | Switches baseline loggers and other shell I/O features with prettier versions, using the `gum` CLI tool. | |
| `treefmt`     | Integrates with `treefmt-nix` and adds its wrapped package to the environment. | `treefmt-nix` in inputs |
| `prek-hooks`  | Manages the `prek` git-hooks tool and manages automatic hooks installation | |

## Known Issues

- **nix-your-shell** and **nix-output-monitor** (nom): it may, in some configurations, spawn two shells, which may lead to duplicate messages and unpredictable behavior

## Credits

- [devenv](https://github.com/cachix/devenv) - Main inspiration for project, a source of its source-code was studied for learning
- [git-hooks.nix](https://github.com/cachix/git-hooks.nix) - Inspiration for making the `prek-hooks` addon
