# Using corepkgs

:::{note}
corepkgs is the **base layer** other package sets build on. Use **ekapkgs**
unless you are building that layer itself.
:::

There are two things you can do with corepkgs, and every route below shows both:
**build a package**, or **get a development shell** for the tools you work in.

## Build a package

You have a derivation to build and you want corepkgs' stdenv and packages behind
it. This is the heavier setup: a package file, its source, and an entry point that
names it.

- [Flakes](flake-input.md) — your project already uses flakes.
- [Inputless flakes](inputless-flake.md) — you want the `nix` CLI, but no flake
  inputs for it to resolve.
- [Npins](npins.md) — your project is plain Nix files.

## Get a development shell

You want the compiler, the interpreters and the tools, with nothing built. This is
lighter: one file, no package.

Every route above has a "Get a development shell" section, and none of them need
anything under `pkgs/`.

## Before your first build

Whichever route you pick, [declare the binary cache](binary-cache.md) first.
Without it, the first build compiles a compiler from source.

## Next steps

- **Building packages against corepkgs** — [Corepkgs vs. Nixpkgs](../introduction/corepkgs-vs-nixpkgs.md)
  lists what behaves differently from nixpkgs.
- **Writing your own package** — [Building Packages](../building-packages/README.md)
  takes one failure mode at a time.
