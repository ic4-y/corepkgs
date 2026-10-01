# Python Package Build Issues

Python packages fail for several distinct reasons after a version bump, and the
fix depends on which one you have.

## The build backend changed

Projects switch backends between releases, most often from `setuptools` to
`hatchling`, or the reverse.

```console
ERROR Backend subprocess exited when trying to invoke get_requires_for_build_wheel
```

Update `build-system` to match, and change the function arguments to import the
new backend and drop the old one:

```nix
# Before
build-system = [ setuptools setuptools-scm ];

# After
build-system = [ hatchling hatch-vcs ];
```

## A version pin is narrower than what corepkgs has

`pyproject.toml` may pin a version range that the package in corepkgs falls
outside of.

```console
ERROR setuptools_scm._overrides:version ... is not in range ...
```

Relax the pin in the build:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail ', "setuptools-scm>=8,<11"' ""
'';
```

## An optional dependency is unavailable

A new version can add an optional dependency that corepkgs does not carry. When
it is not needed for the package to work, drop it:

```nix
pythonRemoveDeps = [ "sphinx-notfound-page" ];
```

## Cython is pinned too narrowly

```console
ERROR Cython version mismatch
```

The same shape as the `setuptools-scm` pin above:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail 'Cython>=3.2.4' 'Cython'
'';
```

## Test files moved or disappeared

```console
FileNotFoundError: conftest.py
```

Upstream restructured its tests, and an install step that copies them now copies
a path that is gone. Copy only what still exists:

```nix
# Before
postInstall = ''
  mkdir $testout
  cp -R conftest.py tests $testout
'';

# After — conftest.py was removed upstream
postInstall = ''
  mkdir $testout
  cp -R tests $testout
'';
```

## pyproject.toml carries an unknown key

```console
ERROR Failed to parse pyproject.toml: unknown key "coherent.licensed"
```

New plugin keys appear faster than they land in corepkgs. Remove the reference:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail '"coherent.licensed",' ""
'';
```

## A Python dependency fails, not the package

```console
error: Build failed due to failed dependency
```

The package builds, but one of its Python dependencies does not. This is not
fixable in the failing package's own file — see [Dependency
Failures](dependency-failures.md), which is where that failure mode is covered.
