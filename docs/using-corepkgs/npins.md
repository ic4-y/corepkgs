# Npins

**Use this if your project does not use flakes.** `npins` pins corepkgs and your
Nix files import that pin, so nothing here is a flake and nothing needs
`flake.lock`.

There are two things to set up, and they are independent: **build a package**, or
**get a development shell**. You can do both in the same project.

## The whole setup

A package takes four files. `default.nix` is the entry point — the file
`nix-build` evaluates; the package lives under `pkgs/`, as it does on every route.

```{code-block} text
:filename: my-project/

  npins/               the pin: which revision of corepkgs, and its hash
  default.nix          the entry point: what this repository builds
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

Two files appear: `npins/default.nix`, which knows how to fetch a pin, and
`npins/sources.json`, which records which revision of corepkgs you asked for. That
second file is the one to commit.

## Build a package

`default.nix` reads the pin and names what this repository builds.

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
the same two files work here, because `callPackage` is doing the same job.

```console
$ nix-build -A hello
$ ./result/bin/hello
hello from corepkgs
```

`nix-build` leaves the package in `./result`, a symlink into the store, and
running it prints the greeting.

:::{caution}
There is no `pkgs.mkShell` in corepkgs, though it is the constructor nixpkgs users
reach for. The equivalent here is `pkgs.mkDevShell`.
:::

## Get a development shell

The tools you work in, with no package built. `shell.nix` is the entry point for
this one — `nix-shell` evaluates it, and there is no flake to declare it in:

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

```console
$ nix-shell
```

A shell with `gcc` and `make` on `PATH`. `exit` leaves it and returns you to your
own shell.
