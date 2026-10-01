# Common Build Issues

A version bump fails in a handful of recognisable ways. Each page below takes
one of them: what the failure looks like, why it happens, and the fix.

Start with [Obsolete Patches](obsolete-patches.md) if the error mentions a patch
or a hunk. It is the most common failure after a bump, and it is the one worth
ruling out before reading anything else.

| Guide | When to use |
|-------|-------------|
| [Obsolete Patches](obsolete-patches.md) | A patch is reversed, or a hunk fails to apply |
| [Dependency Failures](dependency-failures.md) | The error names a package other than the one you are updating |
| [Compiler Errors](compiler-errors.md) | A warning promoted to an error, or a missing header |
| [CMake Packages](cmake-packages.md) | Install paths look wrong, or a configure option disappeared |
| [Python Packages](python-packages.md) | A build backend changed, or a version pin is too strict |
| [Rust and Go Packages](rust-packages.md) | `cargoHash` or `vendorHash` no longer matches |
