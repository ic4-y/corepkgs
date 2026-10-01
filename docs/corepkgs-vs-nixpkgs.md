# Corepkgs vs. Nixpkgs

corepkgs stays as close to nixpkgs as it can, but it is not obliged to keep
nixpkgs' poorer interfaces. Everything below is a deliberate divergence, with the
reasoning, so a reader who finds nixpkgs behaving differently knows why.

## Stdenv

The stdenv differs substantially and has its own README, at `stdenv/README.md` in
this repository.

## Unfree packages

Nixpkgs defaults `config.allowUnfree` to `false` and expects you to opt in.
corepkgs defaults it to `true`, because the point of the fork is to build the
software you asked for rather than to warn you about it. The separate allow-list
is gone: `config.allowUnfreePackages` is now `config.licenses.accept`.

## Evaluation is pure

Impure locations such as `~/.config/nix` are no longer consulted for `config` or
`overlays`, so an evaluation depends only on what it was given. `config.gitConfig`
and `config.gitConfigFile` were removed for the same reason: changing git's
behaviour globally is a machine-level concern, not a build-level one.

## Flakes

`lib.mkFlake` is exposed as a utility for building a flake's output structure, so
a repository does not hand-assemble `packages`, `devShells` and `checks` in every
flake.

## Derivations are structured

`__structuredAttrs = true` is the default here, which means derivation attributes
are arrays rather than space-separated strings. That changes how flags are passed:

- `cmakeEntries` takes an attrset of `-D` cache entries — `{ BUILD_TESTING = false; }` —
  and canonicalises booleans to `ON`/`OFF`. The `cmakeFlags` list still works for
  non-`-D` flags.
- `mesonEntries` takes an attrset of `-D` options — `{ tests = false; systemd = "disabled"; }` —
  canonicalising booleans to `true`/`false`, with feature options taking
  `"enabled"`, `"disabled"` or `"auto"`. `mesonFlags` still works for non-`-D` flags.
- `mesonBuildType` defaults to `release` rather than nixpkgs' `plain`, so a
  Meson package ships something optimised unless it says otherwise.

## Tests do not run by default

`doCheck` defaults to `false` across the package set, so a package's test suite is
not executed as part of its build. The critical path stays lean, and a change to a
test-only input stops rebuilding the world. Run a package's tests explicitly, with
`doCheck = true`, or evaluate the dedicated derivation at `pkg.passthru.tests.*`.

`buildPythonPackage` takes this further with `testPaths`, a list of the files and
directories that make up a package's test suite:

```nix
testPaths = [ "tests" "smartypants" "README.rst" ];
```

A non-empty `testPaths` produces a separate `test_src` output holding just those
paths, plus a `passthru.tests.python` derivation that runs the suite against the
installed package. Because that derivation skips the configure, build and install
phases, running the tests no longer rebuilds the package — so a test failure, or
churn in a test-only dependency, stops invalidating downstream consumers.

## Repository layout

A package lives where its attribute path says it does. `pkgs.vim` is at
`pkgs/vim`; `python3.pkgs.requests` is at `python/pkgs/requests/`. The logic that
used to sit in `build-support/` has been dispersed to the packages that use it.
