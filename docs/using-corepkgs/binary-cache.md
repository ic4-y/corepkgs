# Binary cache

**Every consumer should declare this.** corepkgs publishes its build outputs to a
binary cache. Omitting it does not fail, but the first build compiles a compiler
from source instead of downloading one.

:::{caution}
Declare the cache before your first build. `nixConfig` is not inherited across a
flake input or a pin, so a consumer that omits it compiles a compiler from source
— the same `hello` package took over 13 minutes that way, and 2.9 seconds with it.
:::

Declare it in the `flake.nix` that consumes corepkgs — this is the input route,
but every consumer needs the same two values:

```{code-block} nix
:filename: flake.nix

nixConfig = {
  extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
  extra-trusted-public-keys = [
    "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
  ];
};
```

A no-flake project declares the same two values with `--option` on each command,
or in `nix.conf`:

```console
$ nix-build --option substituters https://ekala-corepkgs.cachix.org \
            --option trusted-public-keys "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
```

## What declaring it does and does not mean

The cache is a personal server and should be treated as untrusted.

It is also **incomplete** — a build with it declared still compiled `pkg-config`
and `glibc` when the cache lacked them — so declaring it means "build only what
is missing" rather than "build nothing".
