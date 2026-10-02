# Adding Packages

A package in corepkgs is one directory: `pkgs/<name>/default.nix`. The attribute
set finds it by name, so `pkgs/foo/default.nix` becomes `pkgs.foo` with nothing to
register.

This page covers what belongs here, how to add it, and a worked example.

## What belongs here

corepkgs is a base layer, not a general package set. It is deliberately narrower
than nixpkgs, and that is what lets updates land more often and rebuild less.

These belong:

- the stdenv, and the compilers, interpreters and toolchains it needs
- common language ecosystem tools — popular linters, package managers, build
  systems
- logic around overlays and package scopes
- the ecosystems a system needs to exist, such as systemd, and their dependencies

An end-user application usually does not. If it exists to be used rather than to
build other things, it probably belongs in a set built on top of this one.

:::{tip}
The test is dependency direction. If nothing in corepkgs would depend on it, it is
not part of corepkgs.
:::

## Where the file goes

`pkgs/` is imported by directory. Each subdirectory is a package, and its
`default.nix` is called with the package set:

```{code-block} text
:filename: pkgs/

  mtdev/
    default.nix          becomes pkgs.mtdev
  nettle/
    default.nix          becomes pkgs.nettle
    generic.nix          (a second file, called from default.nix)
```

Any file in the directory is yours to use; only `default.nix` is the entry point.
`nettle` keeps its build in `generic.nix` so `default.nix` can hold just the
version and the source.

## Add one

1. Create `pkgs/<name>/default.nix`.
2. Take the arguments you need. `callPackage` fills them in from the set.
3. Build with `stdenv.mkDerivation`.
4. Run `./ci/eval.sh` to check it evaluates.

```{code-block} nix
:filename: pkgs/mtdev/default.nix

{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mtdev";
  version = "1.1.7";

  src = fetchurl {
    url = "https://bitmath.org/code/mtdev/mtdev-${finalAttrs.version}.tar.bz2";
    hash = "sha256-oQetrSEB/srFSsf58OCg3RVdlUGT2lXCNAyX8v8dgU4=";
  };

  meta = {
    description = "Multitouch Protocol Translation Library";
    homepage = "https://bitmath.org/code/mtdev/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
```

Four things are worth reading in it.

**The argument list is the dependency list.** `{ lib, stdenv, fetchurl }` asks the
set for three things, and names them. Nothing is reached out of scope.

**`finalAttrs` is how version is read back.** `pname`, `version` and `src` are
declared once, and the URL interpolates `finalAttrs.version` rather than repeating
the string.

**The hash is content, not a checksum you type.** Get a wrong one and the build
stops and tells you the right one. Copy it from that message.

**`meta` is not decoration.** CI enables `checkMeta`, and an unknown or malformed
field fails the build naming the package.

## Check it

```console
$ ./ci/eval.sh
```

That evaluates every package in the repository, including yours. It catches the
failures a build would not: a missing `callPackage` argument, a missing attribute,
or a type error.

Then build it:

```console
$ nix-build -A mtdev
```

## If it needs a second file

Put it beside `default.nix` and call it. `nettle` keeps its version and hash in
`default.nix` and its build in `generic.nix`:

```{code-block} nix
:filename: pkgs/nettle/default.nix

{ callPackage, fetchurl }:

callPackage ./generic.nix rec {
  version = "3.10.2";

  src = fetchurl {
    url = "mirror://gnu/nettle/nettle-${version}.tar.gz";
    hash = "sha256-/p/1HLHyq7XmWmuMEKktoKtaturybn/CtnXEXx+1GbU=";
  };
}
```

Use this when a package has more than one version, or when the build is long enough
that the version and source are worth separating from it.
