# Building Packages

**A version bump fails in a handful of recognisable ways.** Each page below takes
one of them: what the failure looks like, why it happens, and the fix.

## Start here

You need the failing build's log in front of you, and the package's own `.nix`
file. Every page below reads the error you are already looking at.

Start with [Obsolete Patches](obsolete-patches.md) if the error mentions a patch
or a hunk. It is the most common failure after a bump, so rule it out before
reading anything else.

- [Obsolete Patches](obsolete-patches.md) — a patch is reversed, or a hunk fails to
  apply.
- [Dependency Failures](dependency-failures.md) — the error names a package other
  than the one you are updating.
- [Compiler Errors](compiler-errors.md) — a warning promoted to an error, or a
  missing header.
- [CMake Packages](cmake-packages.md) — install paths look wrong, or a configure
  option disappeared.
- [Python Packages](python-packages.md) — a build backend changed, or a version pin
  is too strict.
- [Rust and Go Packages](rust-packages.md) — `cargoHash` or `vendorHash` no longer
  matches.

Two of corepkgs' own defaults cause failures that look like something else, and
are worth knowing before you read a symptom:

- **`strictDeps` is on.** A build that reaches for a program it never declared
  fails rather than finding it on `PATH` by accident.
- **`doCheck` is off.** A package's tests do not run as part of its build, so a
  test failure is not what broke your update.

Both are described in [Corepkgs stdenv](../stdenv/README.md).
