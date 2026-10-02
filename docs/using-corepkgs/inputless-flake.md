# Inputless flakes

**Use this if you want the flake CLI without flake inputs.** `nix develop`,
`nix build` and `nix flake show` all work as usual, but nothing is resolved:
`npins` pins corepkgs and the `flake.nix` reads that pin.

:::{tip}
A flake input also brings in corepkgs' own inputs — `nix-lib`, `treefmt-nix`,
`systems`, `nixpkgs`, `ekala-org` — which a consumer never uses. The inputless
form evaluates `default.nix` instead and resolves none of them.
:::

**What the trade costs you.** `nix flake update` no longer moves corepkgs —
`npins update` does — so a project that expects one command to refresh everything
now has two. A repository whose only input is a package set loses nothing by
doing so.

`flake.nix`:

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
`import sources.corepkgs` resolves to a function taking `{ system }`, not to a
package set — so it must be CALLED with one. Measured.
:::

```console
$ nix build .#hello
$ nix develop
```
