# Inputless flakes

**Use this if you want the flake CLI without flake inputs.** `nix develop`,
`nix build` and `nix flake show` all work as usual, but nothing is resolved:
`npins` pins corepkgs and the `flake.nix` reads that pin.

There are two things to set up, and they are independent: **build a package**, or
**get a development shell**. The file is the same shape for both.

## The whole setup

One file, plus the pin. There is no `inputs` block, so there is nothing for Nix to
resolve before it can evaluate.

```{code-block} text
:filename: my-project/

  npins/               the pin: which revision of corepkgs, and its hash
  flake.nix            the entry point, with no inputs of its own
  pkgs/
    hello/
      default.nix      the package, if you are building one
      hello.c          its source
```

:::{tip}
A flake input also brings in corepkgs' own inputs — `nix-lib`, `treefmt-nix`,
`systems`, `nixpkgs`, `ekala-org` — which a consumer never uses. The inputless
form evaluates `default.nix` instead and resolves none of them.
:::

## Build a package

Both outputs named, so you can build the package and develop in the same shell.

```{code-block} nix
:filename: flake.nix

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

:::{caution}
`import sources.corepkgs` is a function, not a package set — call it with a
system: `import sources.corepkgs { inherit system; }`.
:::

```console
$ nix build .#hello
$ nix develop
```

## Get a development shell

The same file with the `packages` output removed — for a repository that only
wants the toolchain:

```{code-block} nix
:filename: flake.nix

{
  outputs =
    { self }:
    let
      sources = import ./npins;
      corepkgs = import sources.corepkgs;
      forAllSystems = f: { x86_64-linux = f "x86_64-linux"; };
    in
    {
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
$ nix develop
```

## What the trade costs

`nix flake update` no longer moves corepkgs — `npins update` does — so a project
that expects one command to refresh everything now has two. A repository whose
only input is a package set loses nothing by doing so.
