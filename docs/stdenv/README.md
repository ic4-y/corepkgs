# Corepkgs stdenv

`stdenv` is the standard environment a derivation is built in: the compiler and
linker, the shell that runs each build phase, and the defaults those phases
follow. Almost every package in this set is built with `stdenv.mkDerivation`, so
the stdenv's behaviour shows up in nearly every build.

corepkgs replaces nixpkgs' stdenv with its own. It is what the rest of the
package set is built on, and it is the reason this project exists.

## What makes it different

Two properties account for most of the difference, and most of the surprises when
a package is brought over from nixpkgs.

It is **stricter**. A build must declare the tools it uses, rather than finding
them on `PATH` by accident. This is what makes a package's dependencies a fact
about the expression instead of a property of whatever happened to be installed.

It is **more parallel**. Building, checking and installing all use `-j` by
default, because that is what you want on the machine doing the work.

Both are deliberate: the goal is a stdenv that is explicit about what a build
needs, and that uses the machine it is given.

- [Differences from nixpkgs](differences.md) — the six defaults that differ, and
  the one that breaks packages most often.
- [Platforms](platforms.md) — what it builds on, and building it yourself.
- [Darwin](darwin.md) — the port: updating LLVM, the names that moved, and what is
  not verified.

The code lives in `stdenv/`, which holds the stdenv, the spliced packages, and the
construction of the package set from a set of overlays.
