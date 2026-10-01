# Using corepkgs

:::{note} Most users want ekapkgs, not corepkgs
corepkgs is the **base layer**: the stdenv, the compilers, the language ecosystems,
and the module-system behaviour that other package sets build on. It deliberately
carries no desktop applications, no end-user tooling and no distribution
opinions.

If you want to install software or build a system, use **ekapkgs**, which
re-exports corepkgs and adds the rest. Reach for corepkgs directly when you are
building the layer underneath — a package set of your own, a cross-compilation
target, or something that has to sit below ekapkgs.

A useful test: if you would not be surprised to find the thing in
`nixpkgs/pkgs/stdenv/`, it belongs here.
:::

Everything below assumes a `x86_64-linux` machine. Substitute your own system
where it appears.

## Declare the binary cache, or build a compiler

**Do this first. It is the difference between a two-second build and twenty
minutes.**

`nixConfig` is **not inherited** across a flake input or an `npins` pin. A
consumer that does not re-declare corepkgs' cache will bootstrap GCC from source
to build anything at all.

```nix
nixConfig = {
  extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
  extra-trusted-public-keys = [
    "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
  ];
};
```

Measured on the examples below, building the same `hello` package:

| Cache declared | Result |
| --- | --- |
| no | the stdenv, GCC and glibc all compile from source; the build was still going at **13 minutes** |
| yes | the stdenv substitutes and the package builds in **2.9 seconds** |

The cache is a personal server and should be treated as untrusted.

**It is not complete, and you will notice.** A build with the cache declared
still compiled `pkg-config` and `glibc` when the cache lacked them, so declaring
it turns "always build everything" into "build whatever is missing" rather than
into "never build anything". That is still the difference that matters.

## A flake with corepkgs as an input

`corepkgs.lib.mkFlake` builds the output structure for you — `packages`,
`devShells`, `checks` and the rest — so a consumer flake states only what it
adds.

```nix
{
  inputs.corepkgs.url = "github:ekala-project/corepkgs";

  outputs =
    { corepkgs, ... }:
    corepkgs.lib.mkFlake {
      packages =
        pkgs:
        rec {
          hello = pkgs.stdenv.mkDerivation {
            pname = "hello";
            version = "1.0";
            src = pkgs.writeText "hello.c" ''
              #include <stdio.h>
              int main(void) { printf("hello from corepkgs\n"); return 0; }
            '';
            dontUnpack = true;
            buildPhase = "$CC -o hello $src";
            installPhase = "mkdir -p $out/bin && cp hello $out/bin/";
          };
        };

      devShells =
        pkgs:
        {
          default = pkgs.mkShell {
            packages = [ pkgs.gcc pkgs.gnumake ];
          };
        };
    };
}
```

```console
$ nix build .#hello
$ ./result/bin/hello
hello from corepkgs
```

:::{caution} The facade lives at `lib.mkFlake`, not at the flake root
`mk-flake.nix`'s own header shows `core-pkgs.mkFlake { ... }`. That form fails
with `attribute 'mkFlake' missing` — the function is exposed on the `lib` output
(`flake.nix`: `lib = nix-lib // { mkFlake = ...; }`). Measured.
:::

`mkFlake` takes `config`, `overlays`, `modules` and `systems` alongside the
output functions, so a consumer can extend the package set without abandoning the
facade:

```nix
corepkgs.lib.mkFlake {
  overlays = [ (final: prev: { myThing = final.callPackage ./my-thing.nix { }; }) ];
  packages = pkgs: { inherit (pkgs) myThing; };
}
```

:::{caution} `mkShell` is not in corepkgs
`pkgs.mkShell` — the shell constructor nixpkgs users reach for — **does not
exist** here. Measured: evaluating `pkgs ? mkShell` against corepkgs returns
`false`, while `pkgs ? mkDevShell` returns `true`. The two are not
interchangeable: `mkDevShell` takes the same `packages` list and adds the
services layer below.
:::

## A development shell

`pkgs.mkDevShell` is corepkgs' own shell constructor, and the only one — there is
no `mkShell`. It takes a `packages` list like nixpkgs' does, and adds a services
layer on top: a shell can declare processes that start with it, rather than a
`shellHook` that backgrounds them and a comment asking you to remember to kill
them.

```nix
{
  inputs.corepkgs.url = "github:ekala-project/corepkgs";

  # Without this, entering the shell builds a compiler first. See above.
  nixConfig = {
    extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
    extra-trusted-public-keys = [
      "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
    ];
  };

  outputs =
    { corepkgs, ... }:
    corepkgs.lib.mkFlake {
      devShells =
        pkgs:
        {
          default = pkgs.mkDevShell {
            packages = [ pkgs.gcc pkgs.gnumake ];

            services.http-server = {
              enable = true;
              command = "${pkgs.python3}/bin/python3";
              args = [ "-m" "http.server" "8080" ];
              restartPolicy = "always";
            };
          };
        };
    };
}
```

```console
$ nix develop
$ curl -s localhost:8080 | head -1
```

The server is up for as long as the shell is, and its lifetime is the shell's
rather than a stray process you have to find later.

## Without flakes: `npins` and an inputless flake

A flake with no inputs still needs `nix develop` and `nix build`, and `npins`
gives it a pinned corepkgs without a `flake.lock` or a registry lookup.

```console
$ nix run nixpkgs#npins -- -d npins init
$ nix run nixpkgs#npins -- -d npins add github ekala-project corepkgs --name corepkgs
```

```nix
{
  # NO inputs, and no flake.lock to go with them.
  description = "A flake pinned with npins";

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
          hello = pkgs.stdenv.mkDerivation {
            pname = "hello";
            version = "1.0";
            src = pkgs.writeText "hello.c" ''
              #include <stdio.h>
              int main(void) { printf("hello from corepkgs\n"); return 0; }
            '';
            dontUnpack = true;
            buildPhase = "$CC -o hello $src";
            installPhase = "mkdir -p $out/bin && cp hello $out/bin/";
          };
        }
      );
    };
}
```

`import sources.corepkgs` resolves to a **functor** — a function taking
`{ system }` — which is why it is called with one rather than applied directly.
Measured: `import ./npins/corepkgs.nix` does not exist under current `npins`;
the pins are read through `import ./npins`, and each name resolves to its
fetcher.

The `nixConfig` block above still applies, and matters more here: a flake input
at least carries its own `nixConfig` to a reader, while a pin carries nothing.

## Without flakes at all

`npins` reads fine outside a flake, because `default.nix` is an ordinary file.

```nix
# default.nix
let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
pkgs.stdenv.mkDerivation {
  pname = "hello";
  version = "1.0";
  src = pkgs.writeText "hello.c" ''
    #include <stdio.h>
    int main(void) { printf("hello from corepkgs\n"); return 0; }
  '';
  dontUnpack = true;
  buildPhase = "$CC -o hello $src";
  installPhase = "mkdir -p $out/bin && cp hello $out/bin/";
}
```

```console
$ nix-build
$ ./result/bin/hello
hello from corepkgs
```

```nix
# shell.nix — the same pin, opened as a shell
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

`nix-build` and `nix repl` carry over from nixpkgs because corepkgs' `default.nix`
takes a plain `system` the same way nixpkgs' does — measured: the `default.nix`
above builds and runs.

`nix-shell` is the one to be careful with. `mkDevShell` composes the services
layer, which expects a dev-shell lifecycle; under a plain `nix-shell` the
services machinery may not reach a state where the shell is handed over. Use
`nix develop` where you can, and keep a `shell.nix` to `pkgs.mkDevShell` only if
you have measured that it enters on your machine.
