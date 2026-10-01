# Rust and Go Packages

Both ecosystems vendor their dependencies and record the result as a hash, so a
version bump changes that hash in a way that has nothing to do with your change.

## Rust: the cargoHash no longer matches

Updating a Rust package's version and source hash leaves `cargoHash` stale,
because `Cargo.lock` moved with the source.

```console
hash mismatch in fixed-output derivation '/nix/store/...-...-vendor.tar.gz':
  specified: sha256-OLD...
  got:       sha256-NEW...
```

Replace the old hash with the one the error reports:

```nix
cargoHash = "sha256-NEW...";
```

Where the updater normally handles this and failed, the correct hash is in its
output.

## Go: go.mod requires a newer Go than is available

```console
go: go.mod requires go >= 1.26.4 (running go 1.26.3)
```

Either relax the requirement:

```nix
postPatch = ''
  substituteInPlace go.mod --replace-fail 'go 1.26.4' 'go 1.26.3'
'';
```

Or build with a Go that satisfies it:

```nix
# buildGoModule -> buildGo126Module
```

## Go: the vendorHash no longer matches

The same shape as `cargoHash`. Replace it with the hash from the error.
