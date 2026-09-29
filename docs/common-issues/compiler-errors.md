# Compiler Errors

## Warnings treated as errors (-Werror)

New compiler versions or new source code may trigger warnings that are promoted to errors by `-Werror` in the upstream build system.

### Symptom

```console
error: format-overflow [-Werror=format-overflow]
```

Or any `[-Werror=...]` error.

### Fix

Suppress the specific warning:

```nix
env.NIX_CFLAGS_COMPILE = "-Wno-error=format-overflow";
```

For multiple warnings:

```nix
env.NIX_CFLAGS_COMPILE = toString [
  "-Wno-error=format-overflow"
  "-Wno-error=deprecated-declarations"
];
```

:::{caution} Suppress the warning, not the warning class
Only suppress the specific warning. `-Wno-error` on its own silences every warning in the
build, which hides the next real one behind the one you were fixing.
:::

## Configure flags for optional features

Some packages gain or lose optional dependencies between versions. If a feature was auto-detected before but the detection breaks, explicitly disable it:

```nix
configureFlags = [
  "--disable-logind"  # feature removed or dependency unavailable
];
```

## Missing standard headers

New versions of glibc or musl may move or remove headers. If `#include <foo.h>` fails, check if the header was deprecated and if a patch exists upstream.
