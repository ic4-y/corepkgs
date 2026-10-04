# Flakes

**Use this if your project already uses flakes.** `corepkgs.lib.mkFlake` builds
the output structure, so your `flake.nix` states only what you add.

There are two things to set up, and they are independent: **build a package**, or
**get a development shell**. You can do both in the same file.

## The whole setup

A package takes three files. `flake.nix` is the entry point — it names corepkgs
and declares what you set up; the package itself lives under `pkgs/`, one
directory per package.

```{code-block} text
:filename: my-project/

  flake.nix            the entry point: inputs, and what you set up
  pkgs/
    hello/
      default.nix      the package: what it is, and how to build it
      hello.c          its source
```

A development shell needs `flake.nix` alone. Everything under `pkgs/` is unused.

## Build a package

`flake.nix` names the package in its `packages` output.

```{code-block} nix
:filename: flake.nix

{
  inputs.corepkgs.url = "github:ekala-project/corepkgs";

  nixConfig = {
    extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
    extra-trusted-public-keys = [
      "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
    ];
  };

  outputs =
    { corepkgs, ... }:
    corepkgs.lib.mkFlake {
      packages = pkgs: {
        hello = pkgs.callPackage ./pkgs/hello { };
      };
    };
}
```

:::{caution}
Call it as `corepkgs.lib.mkFlake`, not `corepkgs.mkFlake`. The facade is on the
`lib` output, and the root form fails with `attribute 'mkFlake' missing`.
:::

The package is its own file. `callPackage` supplies `lib` and `stdenv` from the
set, so it declares only what it uses.

```{code-block} nix
:filename: pkgs/hello/default.nix

{ lib, stdenv }:

stdenv.mkDerivation {
  pname = "hello";
  version = "1.0";
  src = ./hello.c;
  dontUnpack = true;
  buildPhase = "$CC -o hello $src";
  installPhase = "mkdir -p $out/bin && cp hello $out/bin/";
}
```

Its source sits beside it.

```{code-block} c
:filename: pkgs/hello/hello.c

#include <stdio.h>

int main(void) {
  printf("hello from corepkgs\n");
  return 0;
}
```

```console
$ nix build .#hello
$ ./result/bin/hello
hello from corepkgs
```

The build leaves the package in `./result`, a symlink into the store, and running
it prints the greeting — so both the build and the program are confirmed.

## Get a development shell

The tools you work in, with no package built. This is the same file with a
`devShells` output in place of `packages`, and nothing under `pkgs/`:

```{code-block} nix
:filename: flake.nix

{
  # The same `inputs` and `nixConfig` as above.

  outputs =
    { corepkgs, ... }:
    corepkgs.lib.mkFlake {
      devShells = pkgs: {
        default = pkgs.mkDevShell {
          packages = [ pkgs.gcc pkgs.gnumake ];
        };
      };
    };
}
```

```console
$ nix develop
```

A shell with `gcc` and `make` on `PATH`. `exit` leaves it.
