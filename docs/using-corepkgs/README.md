# Using corepkgs

Three ways to depend on corepkgs, compared side by side: a flake input, an
inputless flake, and npins with no flakes. Pick the one that matches how your
project already gets its dependencies — they are not a progression to work
through.

:::{note}
corepkgs is the **base layer** other package sets build on. Use **ekapkgs**
unless you are building that layer itself.
:::

Three ways to consume corepkgs. Each shows the same two things — a development
shell and a package — so you can compare them rather than take one on faith.

- [Flakes](flake-input.md) — your project already uses flakes.
- [Inputless flakes](inputless-flake.md) — you want the `nix` CLI, but no flake
  inputs for it to resolve.
- [Npins](npins.md) — your project is plain Nix files.

Pick the one that fits. They are not a progression to work through.

## Before your first build

Whichever route you pick, [declare the binary cache](binary-cache.md) first.
Without it, the first build compiles a compiler from source.

## Next steps

Once the pin exists and the cache is declared, the page you want next depends on
what you are doing:

- **Building packages against corepkgs** — [Corepkgs vs. Nixpkgs](../introduction/corepkgs-vs-nixpkgs.md)
  lists what behaves differently from nixpkgs.
- **Writing your own package** — [Building Packages](../building-packages/README.md)
  takes one failure mode at a time.
