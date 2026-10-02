# Npins

**Use this if your project does not use flakes.** `npins` pins corepkgs and your
Nix files import that pin, so nothing here is a flake and nothing needs
`flake.lock`.

Run these once, in the repository's root, to create the pin:

```console
$ nix run nixpkgs#npins -- -d npins init
$ nix run nixpkgs#npins -- -d npins add github ekala-project corepkgs --name corepkgs
```

`default.nix` reads the pin, and the package lives in its own file exactly as it
does under the flake:

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

:::{caution}
There is no `pkgs.mkShell` in corepkgs, though it is the constructor nixpkgs users
reach for. The equivalent here is `pkgs.mkDevShell`.
:::

`shell.nix`:

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

`pkgs/hello/default.nix` and `pkgs/hello/hello.c` are unchanged from
[the flake route](flake-input.md) — the same two files work under every route,
because `callPackage` is doing the same job in each:

```console
$ nix-build -A hello
$ ./result/bin/hello
hello from corepkgs
$ nix-shell
```
