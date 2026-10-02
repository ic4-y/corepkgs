# Differences from nixpkgs

Six defaults differ from nixpkgs. Each is a deliberate change, and the first two
are the ones most likely to surprise a package brought over from nixpkgs.

**`strictDeps = true`** — build inputs and host inputs are kept apart. A build that
reaches for a program it did not declare fails, rather than quietly finding it on
`PATH`.

**`__structuredAttrs = true`** — derivation attributes are arrays, not
space-separated strings.

**`isCross` is defined** — the attribute exists here. Upstream leaves it absent on
a native build.

**`enableParallelBuilding`, `enableParallelChecking`, `enableParallelInstalling`**
all default to `true` — builds, tests and installs use `-j` without being asked.

## `strictDeps` breaks builds that relied on `PATH`

This is the one that breaks packages most often. A build that used a program
without declaring it — a transitive dependency that happened to be visible —
fails to find it. The fix is to add the missing input to `nativeBuildInputs` or
`buildInputs`, which is the declaration the build was missing anyway.

## The other five

`isCross` and the three parallel defaults need no action: they either add an
attribute or start work the build was going to do anyway.

`__structuredAttrs` changes how flags reach a build, and corepkgs ships helpers
for the two most common cases — `cmakeEntries` and `mesonEntries`. Both are
described in [Corepkgs vs. Nixpkgs](../introduction/corepkgs-vs-nixpkgs.md),
which lists every divergence from nixpkgs in one place.
