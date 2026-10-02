# Differences from nixpkgs

Six defaults differ. All six are set in one place.

```{code-block} nix
:filename: stdenv/generic/make-derivation.nix

strictDeps ? true,
__structuredAttrs ? true,
enableParallelBuilding ? true,
enableParallelChecking ? true,
enableParallelInstalling ? true,
```

That is the whole difference. The rest of this page explains what each one means
for a package you are bringing over.

## `strictDeps` — the one that breaks builds

Build inputs and host inputs are kept apart. A build must declare the tools it
uses.

If it does not, it fails. It will not quietly find the tool on `PATH`.

The fix is to declare the input you were relying on:

```{code-block} nix
:filename: pkgs/AvailabilityVersions/default.nix

buildInputs = [ bashNonInteractive ];
nativeBuildInputs = [ unifdef ];
```

This is the failure a package from nixpkgs hits most often. The dependency was
real; it was just never written down.

## `__structuredAttrs` — attributes become real values

A derivation attribute is an array or a boolean, not a string joined by spaces.

corepkgs leans on this. Three helpers read the attributes directly, so you do not
build `-D` flags by hand.

`cmakeEntries` takes a set of cache entries. Booleans become `ON` and `OFF`:

```{code-block} nix
:filename: pkgs/aws-c-common/default.nix

cmakeEntries = {
  BUILD_SHARED_LIBS = true;
};
```

`mesonEntries` does the same for Meson, and feature options take `"enabled"`,
`"disabled"` or `"auto"`:

```{code-block} nix
:filename: pkgs/at-spi2-core/default.nix

mesonEntries = {
  dbus_daemon = "dbus-daemon";
  use_systemd = false;
};
```

`mesonBuildType` defaults to `release`, not nixpkgs' `plain`. A Meson package
ships optimised unless it says otherwise.

```{code-block} nix
:filename: pkgs-many/nix/modular/packaging/components.nix

mesonBuildType = prevAttrs.mesonBuildType or "release";
```

## The parallel three

Builds, checks and installs all use `-j`. Nothing asks for it and nothing needs to
configure it. A package that cannot build in parallel says so with
`enableParallelBuilding = false`.

## `isCross`

The attribute is always defined. nixpkgs omits it on a native build; here it is a
boolean you can read.

```{code-block} nix
:filename: stdenv/generic/default.nix

isCross = hostPlatform != buildPlatform;
```

On a native build it is `false` rather than absent, so a package can test it
directly.

## Tests do not run

`doCheck` follows `config.doCheckByDefault`, which is off.

```{code-block} nix
:filename: stdenv/generic/make-derivation.nix

doCheck ? doCheckByDefault && canExecuteHostOnBuild,
```

So a package's test suite is not part of its build, and a change to a test-only
input does not invalidate downstream packages.

Turn it on with `doCheck = true`, or evaluate the derivation at
`pkg.passthru.tests.*`.
