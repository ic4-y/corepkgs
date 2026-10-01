# Dependency Failures

The package you are updating builds fine on its own, but something it depends on
does not.

## What it looks like

```console
error: Build failed due to failed dependency

these N derivations will be built:
  /nix/store/...-some-other-package.drv
```

The telling detail is that the error names a **different package** than the one
you set out to update. The failing derivation path in that output is the package
that actually broke.

## The fix

:::{caution} The file you are editing is not the one that is broken
Editing the updated package's Nix file cannot fix this. The `.drv` path in the
error names the package that broke, and that is the one to repair.
:::

Repair the broken dependency, then retry the original update.

## Why it happens

A shared dependency was recently updated and broke under it. Or the new version
added a dependency that does not build in corepkgs. Or a circular dependency was
introduced between two packages that previously did not reference each other.

## What not to do

Reach for `--impure`, or skip the sandbox: the failure is a real build failure and
neither changes it. Remove the dependency from `buildInputs`: it is needed, and
removing it moves the failure rather than fixing it. Patch the dependent package
from inside the package you were updating: the fix belongs in the package that
broke.
