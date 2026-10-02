# Adding Packages

A package in corepkgs is one directory: `pkgs/<name>/default.nix`. The attribute
set finds it by name, so `pkgs/foo/default.nix` becomes `pkgs.foo` with nothing to
register.

This page covers what belongs here, how to add it, and a worked example.

## What belongs here

corepkgs is a base layer, not a general package set. Its scope is narrower than
nixpkgs by design, so that updates land more often and less has to be rebuilt when
they do.

Four kinds of thing belong.

**The build environment itself.** The stdenv, and the compilers, interpreters and
toolchains it needs to work.

```{code-block} text
:class: excerpt
:filename: build environment

  pkgs/gcc/                          the default compiler
  pkgs-many/llvm/                    LLVM, several versions
  pkgs-many/gcc-releases/            GCC, several releases
  pkgs-many/binutils/                the linker and binutils
  pkgs-many/autoconf/  automake/     the autotools
  pkgs-many/cmake/  meson/  ninja/   the build systems
```

**Language ecosystems, and the tools around them.** An interpreter or compiler,
plus the ecosystem tooling a project of that language expects — package managers,
linters, test runners.

```{code-block} text
:class: excerpt
:filename: language ecosystems

  python/cpython/      python/pkgs/   the interpreter and 178 packages
  pkgs-many/perl/      perl/pkgs/     the interpreter and 172 packages
  pkgs-many/rust/      pkgs-many/go/  the toolchains
  python/pkgs/pip/     python/pkgs/virtualenv/
  python/pkgs/mypy/    python/pkgs/black/   a type checker and a formatter
  pkgs-many/nodejs/    pkgs-many/pnpm/      a runtime and its package manager
```

**The logic that assembles a package set.** Overlays, package scopes, and the
machinery that turns directories into attributes is part of the product, not an
implementation detail.

```{code-block} text
:class: excerpt
:filename: package-set logic

  stdenv/stage.nix                   layers the package set from overlays
  top-level.nix                      the top-level overlay
  stdenv/splice.nix                  keeps build and host inputs apart
  python/passthrufun.nix             the Python package set's scope
  haskell/make-package-set.nix       the Haskell package set's scope
```

**What a running system needs.** The services and daemons a machine cannot boot
without, and their dependencies.

```{code-block} text
:class: excerpt
:filename: system layer

  pkgs/linux-support/pkgs/systemd/   the init system
  pkgs/dbus/                         the message bus systemd talks to
  pkgs/polkit/                       privilege escalation
  pkgs/linux-support/pkgs/           kernel modules and hardware support
```

An end-user application usually does not belong. If it exists to be used rather
than to build other things, it probably belongs in a set built on top of this one.

:::{tip}
The test is dependency direction. If nothing in corepkgs would depend on it, it is
not part of corepkgs.
:::

## Where the file goes

`pkgs/` is imported by directory. Each subdirectory is a package, and its
`default.nix` is called with the package set. Everything else in the directory is
yours to use.

## Add one

Two packages, added step by step. **`mtdev`** is the multitouch protocol
translation library: it turns raw touchscreen events into gestures. **`nettle`**
is a cryptographic library.

Both are already in this repository. Read what follows as a reconstruction of how
they got there, because between them they are the two shapes a package takes.
`mtdev` is self-contained — one source, one build. `nettle` is not.

There are also the same two packages to look at afterwards, which is the point of
choosing them: the file you end up with is the file that is here.

### `mtdev`, in one file

Create the directory, and put the package in `default.nix`:

```{code-block} text
:filename: pkgs/

  mtdev/
    default.nix          becomes pkgs.mtdev
```

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

### `nettle`, in two

`nettle`'s build is long enough to be worth separating from the version and the
source, and more than one version could exist. So the directory holds both:

```{code-block} text
:filename: pkgs/

  nettle/
    default.nix          the version and the source
    generic.nix          the build, shared by every version
```

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

Only `default.nix` is the entry point. It calls `generic.nix` and passes the
version and source in. `generic.nix` takes them as `version` and `src` and builds
from them, so a second version would be a second caller rather than a second build
description.

`nettle` has one caller today. The split is what makes the second one cheap.

## Check it

```console
$ ./ci/eval.sh
```

That evaluates every package in the repository, including both of these. It
catches the failures a build would not: a missing `callPackage` argument, a
missing attribute, or a type error.

Then build one:

```console
$ nix-build -A mtdev
```

`nix-build` prints the store path it built and leaves `./result` pointing at it, so
`ls result/` is the package you just added.
