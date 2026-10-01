# Obsolete Patches

Patches applied with `fetchpatch` or `fetchurl` record a fix upstream had not
made yet. When upstream lands that fix itself, the patch becomes obsolete, and it
is the most common failure after a version bump.

A patch that applied cleanly last release can reverse or fail the moment upstream
incorporates it. Rule this out before reading anything else in this directory.

## What it looks like

A patch that upstream has already applied:

```console
Reversed (or previously applied) patch detected!  Assume -R? [n]
Apply anyway? [n]
Skipping patch.
1 out of 1 hunk ignored
```

A patch whose surrounding context moved:

```console
applying patch /nix/store/...-fix-something.patch
patching file src/foo.c
Hunk #1 FAILED at 25.
1 out of 1 hunk FAILED -- saving rejects to file src/foo.c.rej
```

## The fix

Remove the patch from the `patches` list, and remove the `fetchpatch` or
`fetchurl` call that fetched it. Any function argument that only existed to fetch
that patch comes out too.

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  # fetchpatch removed — nothing fetched it any more
}:

stdenv.mkDerivation {
  # ...
}
```

## When only some hunks fail

A multi-hunk patch can apply half its hunks and fail the rest. The build then
carries on with a half-patched tree, and fails later somewhere unrelated.

:::{caution}
**A partially-applied patch is worse than one that fails outright.** Regenerate
it against the current source, or split it into the hunks that still apply. If
upstream already fixed the problem, remove the whole patch instead.
:::

## Patches that are not in the package file

Some packages inherit patches from a shared expression — LLVM and elogind both do
this. The patch is then absent from the package's own `patches = [...]` list, and
the failure points at a file you were not editing. Look at the parent expressions
and the `generic.nix` files for those definitions.
