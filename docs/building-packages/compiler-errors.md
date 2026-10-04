# Compiler Errors

New compiler versions and new source code both produce warnings that upstream
build systems promote to errors.

## A warning promoted to an error

```console
error: format-overflow [-Werror=format-overflow]
```

Any `[-Werror=...]` failure has the same shape. Suppress the specific warning:

```nix
env.NIX_CFLAGS_COMPILE = "-Wno-error=format-overflow";
```

Several at once, as a list:

```nix
env.NIX_CFLAGS_COMPILE = toString [
  "-Wno-error=format-overflow"
  "-Wno-error=deprecated-declarations"
];
```

:::{caution}
**Suppress the warning, not the warning class.** A bare `-Wno-error` turns every
warning in the build back into a warning, which hides the next real one behind
the one you were fixing. Name the warning you are silencing.
:::

## An optional feature that stopped being detected

Packages gain and lose optional dependencies between versions, and a feature that
used to be found automatically can stop being found. Disable it explicitly:

```nix
configureFlags = [
  "--disable-logind"  # feature removed, or its dependency is unavailable
];
```

## A header that moved

glibc and musl both move deprecated headers between releases. When `#include
<foo.h>` fails, check whether the header was deprecated or removed, and whether
upstream has a patch for it.
