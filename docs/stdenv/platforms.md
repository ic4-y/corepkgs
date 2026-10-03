# Platforms

corepkgs' stdenv builds on three platforms:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

Darwin has no Intel bootstrap files, so `x86_64-darwin` is not supported. See
[Darwin](darwin.md) for what the port covers and what it does not.

## Building it yourself

`default.nix` is meant to be treated the way nixpkgs' is, so `nix-build` and
`nix repl` workflows carry over unchanged:

```console
$ nix-build -A stdenv
/nix/store/lk2ax3a6mqrm5ddkg3s4f31m33w89k85-stdenv-linux
```

That path is from the upstream README and will differ on your machine. What stays
the same is the attribute, `stdenv`, and that it can be built on its own like any
other package.
