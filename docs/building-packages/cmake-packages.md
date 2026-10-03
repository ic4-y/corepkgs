# CMake Packages

A major version bump can change where CMake installs things, or rename the options
that control it.

## Install paths go wrong

Outputs end up somewhere unexpected, or under `$out/usr/lib` instead of `$out/lib`.

```console
CMake Error at cmake_install.cmake:
  file INSTALL cannot find "/build/source/..."
```

Or the build succeeds and the outputs are empty. Either way, set the install
directories explicitly:

```nix
cmakeFlags = [
  "-DCMAKE_INSTALL_INCLUDEDIR=include"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

Where `cmakeFlags` is already in use, append rather than replace:

```nix
cmakeFlags = [
  "-H.."  # existing flag
  "-DCMAKE_INSTALL_INCLUDEDIR=include"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

## Another package needs your test infrastructure

Some packages build test infrastructure that other packages depend on, and it
only exists when testing is enabled:

```nix
cmakeFlags = [
  "-DBUILD_TESTING=ON"
];
```

## An option was renamed between versions

Check the upstream `CMakeLists.txt` for the current names. `BUILD_SHARED_LIBS`
has stayed stable, but `ENABLE_*`, `WITH_*` and `*_SUPPORT` vary by project, and
the `CMAKE_INSTALL_*DIR` variables follow the GNUInstallDirs conventions rather
than each project's own.
