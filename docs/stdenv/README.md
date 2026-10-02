# Corepkgs stdenv

`stdenv` is the standard environment a package is built in. It is the compiler and
linker, the shell that runs each build phase, and the defaults those phases
follow.

You do not call it directly. You receive it:

```{code-block} nix
:class: excerpt
:filename: pkgs/aws-c-common/default.nix

{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix,
}:
```

Every package takes `stdenv` as an argument. `callPackage` fills it in from the
set, so the package says what it needs and the set supplies it.

## What it consists of

The stdenv is small, and each part is a directory you can read:

```{code-block} text
:class: excerpt
:filename: stdenv/

  generic/             make-derivation.nix: the defaults every package inherits
  cc-wrapper/          the compiler, wrapped with the flags a build expects
  bintools-wrapper/    the linker and binutils, wrapped the same way
  setup-hooks/         the phases: unpack, patch, configure, build, install
  splice.nix           how build and host inputs are kept apart
  linux/  darwin/      the per-platform pieces
```

`generic/default.nix` picks a stdenv for the platform. `make-derivation.nix` is
where the defaults live — the file the [differences](differences.md) page quotes.

## What corepkgs does differently

Two properties account for most of the difference.

It is **stricter**. A build must declare the tools it uses, rather than finding
them on `PATH` by accident. A dependency becomes a fact about the expression.

It is **more parallel**. Building, checking and installing all use `-j` by
default, so a machine with cores actually uses them.
