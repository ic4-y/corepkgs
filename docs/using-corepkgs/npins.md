# With npins, and no flakes

No flakes, no `flake.lock`, nothing to resolve — `npins` pins corepkgs and the
files below are plain Nix. This is the route for a repository that does not use
flakes at all.

`default.nix` reads the pin, and the package lives in its own file exactly as it
does under the flake:

```console
$ nix run nixpkgs#npins -- -d npins init
$ nix run nixpkgs#npins -- -d npins add github ekala-project corepkgs --name corepkgs
```

```nix
let
  sources = import ./npins;
  pkgs = import sources.corepkgs { system = builtins.currentSystem; };
in
{
  hello = pkgs.callPackage ./pkgs/hello { };
}
```

:::{caution}
`pkgs.mkShell` — the constructor nixpkgs users reach for — does not exist here.
Measured: `pkgs ? mkShell` is `false` while `pkgs ? mkDevShell` is `true`.
:::

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

`pkgs/hello/default.nix` and `pkgs/hello/hello.c` are unchanged from
[the flake route](flake-input.md) — the same two files work under every route,
because `callPackage` is doing the same job in each:

```console
$ nix-build -A hello
$ ./result/bin/hello
hello from corepkgs
$ nix-shell
```
