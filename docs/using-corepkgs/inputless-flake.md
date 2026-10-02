# Inputless flakes

**Use this if you want the flake CLI without flake inputs.** `nix develop`,
`nix build` and `nix flake show` all work as usual, but nothing is resolved:
`npins` pins corepkgs and the `flake.nix` reads that pin.

## The layout

The same four files as [the `npins` route](npins.md) — only `flake.nix` is
different, and it has no `inputs` block:

```{code-block} text
:filename: my-project/

  npins/               the pin: which revision of corepkgs, and its hash
  flake.nix            the entry point, with no inputs of its own
  pkgs/
    hello/
      default.nix      the package: what it is, and how to build it
      hello.c          its source
```

:::{tip}
A flake input also brings in corepkgs' own inputs — `nix-lib`, `treefmt-nix`,
`systems`, `nixpkgs`, `ekala-org` — which a consumer never uses. The inputless
form evaluates `default.nix` instead and resolves none of them.
:::

## `flake.nix`

There is no `inputs` block to resolve: the pin is read from `npins`, and the
outputs are built from it.

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

## What the trade costs

`nix flake update` no longer moves corepkgs — `npins update` does — so a project
that expects one command to refresh everything now has two. A repository whose
only input is a package set loses nothing by doing so.

## Build it

```console
$ nix build .#hello
$ nix develop
```
