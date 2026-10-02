# Npins

**Use this if your project does not use flakes.** `npins` pins corepkgs and your
Nix files import that pin, so nothing here is a flake and nothing needs
`flake.lock`.

## The layout

Four files, and a directory `npins` owns. `default.nix` is the entry point — the
file `nix-build` evaluates; the package lives under `pkgs/`, as it does on every
route.

```{code-block} text
:filename: my-project/

  npins/               the pin: which revision of corepkgs, and its hash
  default.nix          the entry point: what this repository builds
  shell.nix            the development shell
  pkgs/
    hello/
      default.nix      the package: what it is, and how to build it
      hello.c          its source
```

## Create the pin

Run these once, in the repository's root:

```console
$ nix run nixpkgs#npins -- -d npins init
$ nix run nixpkgs#npins -- -d npins add github ekala-project corepkgs --name corepkgs
```

## `default.nix`

The entry point. It reads the pin and imports corepkgs from it, then names what
this repository builds.

```{code-block} nix
:filename: default.nix

let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
{
  hello = pkgs.callPackage ./pkgs/hello { };
}
```

The package in `pkgs/hello/` is unchanged from [the flake route](flake-input.md) —
the same two files work here, because `callPackage` is doing the same job in both.

:::{caution}
There is no `pkgs.mkShell` in corepkgs, though it is the constructor nixpkgs users
reach for. The equivalent here is `pkgs.mkDevShell`.
:::

## `shell.nix`

The development shell. `nix-shell` evaluates this file, and there is no flake to
declare it in.

```{code-block} nix
:filename: shell.nix

let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
pkgs.mkDevShell {
  packages = [ pkgs.gcc pkgs.gnumake ];
}
```

## Build it

```console
$ nix-build -A hello
$ ./result/bin/hello
hello from corepkgs
$ nix-shell
```
