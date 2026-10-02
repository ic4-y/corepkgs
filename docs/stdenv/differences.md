# Differences from nixpkgs

Six defaults differ from nixpkgs. Each is a deliberate change, and the first two
are the ones most likely to surprise a package brought over from nixpkgs.

| Difference | What it means |
| --- | --- |
| `stdenv.isCross` is defined | The attribute exists here; upstream leaves it absent on a native build. |
| `strictDeps` defaults to `true` | Build inputs and host inputs are kept apart, so a build that reaches for a program it did not declare fails rather than quietly finding it on `PATH`. |
| `__structuredAttrs` defaults to `true` | Derivation attributes are arrays, not space-separated strings. |
| `enableParallelBuilding` defaults to `true` | Builds use `-j` without being asked. |
| `enableParallelChecking` defaults to `true` | Test phases run in parallel too. |
| `enableParallelInstalling` defaults to `true` | Install phases likewise. |

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
