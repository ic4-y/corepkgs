# Flakes

Use this when your project already uses flakes. `corepkgs.lib.mkFlake` builds the
output structure, so your `flake.nix` states only what you add.

:::{caution}
Call it as `corepkgs.lib.mkFlake`, not `corepkgs.mkFlake`. The facade is on the
`lib` output, and the root form fails with `attribute 'mkFlake' missing`.
:::

`flake.nix`:

```nix
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

The package lives in its own file. `callPackage` supplies `lib` and `stdenv`
from the set, so the file declares only what it uses — `pkgs/hello/default.nix`:

```nix
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

`pkgs/hello/hello.c`, beside it:

```c
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
$ nix develop
```

## A dev shell without a package

The same `flake.nix` without the `packages` output — for a repository that only
wants the toolchain:

```nix
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
