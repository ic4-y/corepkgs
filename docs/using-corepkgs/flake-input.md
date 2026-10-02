# Flakes

**Use this if your project already uses flakes.** `corepkgs.lib.mkFlake` builds
the output structure, so your `flake.nix` states only what you add.

## The layout

Three files do the work. `flake.nix` is the entry point — it names the dependency
and the outputs; the package itself lives under `pkgs/`, one directory per
package.

```{code-block} text
:filename: my-project/

  flake.nix            the entry point: inputs, and the outputs built from them
  pkgs/
    hello/
      default.nix      the package: what it is, and how to build it
      hello.c          its source
```

## `flake.nix`

`flake.nix` is the file Nix reads when you run a `nix` command in the directory.
It has two jobs: name the inputs — here, corepkgs — and declare the outputs built
from them, which is what `mkFlake` structures for you.

:::{caution}
Call it as `corepkgs.lib.mkFlake`, not `corepkgs.mkFlake`. The facade is on the
`lib` output, and the root form fails with `attribute 'mkFlake' missing`.
:::

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

      devShells = pkgs: {
        default = pkgs.mkDevShell {
          packages = [ pkgs.gcc pkgs.gnumake ];
        };
      };
    };
}
```

## `pkgs/hello/default.nix`

The package, in its own file. `callPackage` supplies `lib` and `stdenv` from the
set, so this file declares only what it uses.

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

## `pkgs/hello/hello.c`

Its source, beside it.

```{code-block} c
:filename: pkgs/hello/hello.c

#include <stdio.h>

int main(void) {
  printf("hello from corepkgs\n");
  return 0;
}
```

## Build it

```console
$ nix build .#hello
$ ./result/bin/hello
hello from corepkgs
$ nix develop
```

## A dev shell without a package

The same file without the `packages` output — for a repository that only wants
the toolchain:

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
      devShells = pkgs: {
        default = pkgs.mkDevShell {
          packages = [ pkgs.gcc pkgs.gnumake ];
        };
      };
    };
}
```
