# Using corepkgs

:::{note}
corepkgs is the **base layer** other package sets build on. Use **ekapkgs**
unless you are building that layer itself.
:::

Three ways to consume corepkgs. Each shows the same two things — a development
shell and a package — so you can compare them rather than take one on faith.

| Route | Use it when |
| --- | --- |
| [Flakes](flake-input.md) | Your project already uses flakes. |
| [Inputless flakes](inputless-flake.md) | You want `nix develop`, but no flake inputs to resolve. |
| [Npins](npins.md) | Your project uses plain Nix files. |

Pick the one that fits. They are not a progression to work through.

Whichever you pick, [declare the binary cache](binary-cache.md) before your first
build — without it a consumer bootstraps a compiler from source.
