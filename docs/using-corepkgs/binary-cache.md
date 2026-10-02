# Binary cache

**Every consumer should declare this.** corepkgs publishes its build outputs to a
binary cache. Omitting it does not fail, but the first build compiles a compiler
from source instead of downloading one.

## `flake.nix`

On a flake route, the two values go in the consuming `flake.nix` — the same file
that names corepkgs as an input. This is where you put them:

```{code-block} nix
:filename: flake.nix

{
  inputs.corepkgs.url = "github:ekala-project/corepkgs";

  # NOT INHERITED. A flake input does not carry corepkgs' own nixConfig, so a
  # consumer that omits this block builds the compiler from source.
  nixConfig = {
    extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
    extra-trusted-public-keys = [
      "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
    ];
  };

  outputs = { corepkgs, ... }: corepkgs.lib.mkFlake { };
}
```

## Without flakes

A project using [`npins`](npins.md) has no `flake.nix`, so it declares the same
two values per command, or once in `nix.conf`:

```console
$ nix-build --option substituters https://ekala-corepkgs.cachix.org \
            --option trusted-public-keys "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
```

```{code-block} text
:filename: /etc/nix/nix.conf

substituters = https://ekala-corepkgs.cachix.org
trusted-public-keys = ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w=
```

:::{caution}
Declare it before your first build. The same `hello` package took **over 13
minutes and was still building** without the cache, and **2.9 seconds** with it.
:::

## What declaring it means

The cache is a personal server and should be treated as untrusted.

It is also **incomplete** — a build with it declared still compiled `pkg-config`
and `glibc` when the cache lacked them — so declaring it means "build only what
is missing" rather than "build nothing".
