# `nix-vessel`

This is a library for constructing Nix dev-shells that uses a module system to allow for greater flexibility, i.e. no more `mkShell`.

*In some ways,* this might be seen as an alternative to projects such as devenv.sh, devbox, flox, and others. `nix-vessel` differs in that it tries to be as minimal as possible while providing a solid foundation, sticking to Nix (no JSON/YAML or similar shenanigans), and having minimum footprint.

To that end, the core of the library offers only the basics, and any additional things ("add-ons" described down below) are opt-in behavior. This means only what is needed will be imported and evaluated by Nix.

**IMPORTANT:** This library requires the Nix feature `pipe-operators` to be enabled.

## Feature Comparison

<!-- TODO -->

## Add-ons

<!-- TODO -->

## Credits

- [devenv](https://github.com/cachix/devenv) - Main inspiration for project, a source of its source-code was studied for learning
