# Using corepkgs

:::{note} Most users want ekapkgs
corepkgs is the **base layer** other package sets build on. Use **ekapkgs**
unless you are building that layer itself.
:::

Three ways to consume corepkgs. Each shows the same two things — a development
shell and a package — so you can compare them rather than take one on faith.

| Route | Use it when |
| --- | --- |
| [A flake input](#with-a-flake-input) | Your project already uses flakes. |
| [npins, no flakes](#with-npins-and-no-flakes) | Your project uses plain Nix files. |
| [An inputless flake](#an-inputless-flake) | You want `nix develop`, but no flake inputs to resolve. |

Pick the one that fits. They are not a progression to work through.

## With a flake input

The shortest route, if your project already uses flakes. `corepkgs.lib.mkFlake`
builds the output structure, so your `flake.nix` states only what you add.

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

`pkgs/hello/default.nix` — a package lives in its own file, and `callPackage`
supplies `lib` and `stdenv` from the set, so the file declares only what it uses:

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

:::{caution} The facade lives at `lib.mkFlake`
`mk-flake.nix`'s own header shows `core-pkgs.mkFlake { … }`. That form fails with
`attribute 'mkFlake' missing` — it is exposed on the `lib` output.
:::

## With npins, and no flakes

No flakes, no `flake.lock`, nothing to resolve — `npins` pins corepkgs and the
files below are plain Nix. This is the route for a repository that does not use
flakes at all.

```console
$ nix run nixpkgs#npins -- -d npins init
$ nix run nixpkgs#npins -- -d npins add github ekala-project corepkgs --name corepkgs
```

`default.nix`:

```nix
let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
{
  hello = pkgs.callPackage ./pkgs/hello { };
}
```

`shell.nix`:

```nix
let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
pkgs.mkDevShell {
  packages = [ pkgs.gcc pkgs.gnumake ];
}
```

`pkgs/hello/default.nix` and `pkgs/hello/hello.c` are unchanged from above — the
same package file works under every route, because `callPackage` is doing the
same job in each.

```console
$ nix-build -A hello
$ ./result/bin/hello
hello from corepkgs
$ nix-shell
```

:::{caution} `mkShell` is not in corepkgs
`pkgs.mkShell` — the constructor nixpkgs users reach for — does not exist here.
Measured: `pkgs ? mkShell` is `false` while `pkgs ? mkDevShell` is `true`.
:::

## An inputless flake

The flake CLI, without flake inputs. `nix develop`, `nix build` and `nix flake
show` all work as usual, and nothing is resolved: `npins` pins corepkgs, and the
flake reads that pin.

**What you stop evaluating.** A flake input drags in corepkgs' own inputs. This
consumer's lock carries **8 nodes** — `corepkgs`, plus `nix-lib`, `treefmt-nix`,
`systems`, `nixpkgs` twice and `ekala-org` — none of which a consumer of the
package set has any use for. They are there because corepkgs' `flake.nix` needs
them to build its own tooling. The inputless form evaluates `default.nix` instead
and resolves **none**: measured, `npins` fetches a tarball and the pin is
`import`ed, so the flake's inputs are not part of the evaluation at all.

That is the trade: you keep the flake CLI, and you give up flake inputs. A
repository whose only input is a package set loses nothing by doing so.

**What it costs you.** `nix flake update` no longer moves corepkgs — `npins
update` does — so a project that expects one command to refresh everything now
has two.

`flake.nix`:

```nix
{
  outputs =
    { self }:
    let
      sources = import ./npins;
      corepkgs = import sources.corepkgs;
      forAllSystems = f: { x86_64-linux = f "x86_64-linux"; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = corepkgs { inherit system; };
        in
        {
          hello = pkgs.callPackage ./pkgs/hello { };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = corepkgs { inherit system; };
        in
        {
          default = pkgs.mkDevShell {
            packages = [ pkgs.gcc pkgs.gnumake ];
          };
        }
      );
    };
}
```

```console
$ nix build .#hello
$ nix develop
```

:::{caution} The pin is a functor
`import sources.corepkgs` resolves to a function taking `{ system }`, not to a
package set — so it must be CALLED with one. Measured.
:::

## Declare the binary cache first

:::{caution} Without this, you build a compiler
`nixConfig` is **not inherited** across a flake input or a pin. The same `hello`
package took **13+ minutes and was still building** without the cache, and
**2.9 seconds** with it.
:::

```nix
nixConfig = {
  extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
  extra-trusted-public-keys = [
    "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
  ];
};
```

A no-flake project declares the same two values with `--option` on each command,
or in `nix.conf`:

```console
$ nix-build --option substituters https://ekala-corepkgs.cachix.org \
            --option trusted-public-keys "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
```

The cache is a personal server and should be treated as untrusted. It is also
**incomplete** — a build with it declared still compiled `pkg-config` and `glibc`
when the cache lacked them — so declaring it means "build only what is missing"
rather than "build nothing".
