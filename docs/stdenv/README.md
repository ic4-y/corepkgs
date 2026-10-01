# Stdenv

corepkgs' standard environment is the reason the project exists. It is the base a
larger package set builds on. It is deliberately **stricter and more parallel
than nixpkgs'**.

The code lives in `stdenv/`, which encapsulates the stdenv, the spliced packages
and the construction of the package set from a set of overlays.

## How it differs from nixpkgs

Six defaults differ, each a deliberate change. The first two are the ones most
likely to surprise a package brought over from nixpkgs.

| Difference | What it means |
| --- | --- |
| `stdenv.isCross` is defined | The attribute exists here; upstream leaves it absent on a native build. |
| `strictDeps` defaults to `true` | Build inputs and host inputs are kept apart, so a build that reaches for a program it did not declare fails rather than quietly finding it on `PATH`. |
| `__structuredAttrs` defaults to `true` | Derivation attributes are arrays, not space-separated strings. |
| `enableParallelBuilding` defaults to `true` | Builds use `-j` without being asked. |
| `enableParallelChecking` defaults to `true` | Test phases run in parallel too. |
| `enableParallelInstalling` defaults to `true` | Install phases likewise. |

`strictDeps` is the one that breaks packages most often. A package that relied on
a transitive dependency being visible will fail to find a program it never
declared.

## Supported platforms

- [x] `x86_64-linux`
- [x] `aarch64-linux`
- [x] `aarch64-darwin`

Darwin has no Intel bootstrap files, so `x86_64-darwin` is not supported.

## Building it

`default.nix` is meant to be treated the way nixpkgs' is, so `nix-build` and
`nix repl` workflows carry over unchanged:

```console
$ nix-build -A stdenv
/nix/store/lk2ax3a6mqrm5ddkg3s4f31m33w89k85-stdenv-linux
```

That path is from the upstream README and will differ on your machine; the shape
of the attribute is the point.

## Updating it on Darwin

Update `llvmPackages` for Darwin in `top-level.nix` to match
`llvmPackages.latest`. This is timed against LLVM's release schedule: use the
spring release, and once `llvmPackages.latest` has been moved to match. If LLVM
has announced patch releases, wait until those land in nixpkgs before updating.

Then fix what breaks. Most breakage is additional warnings turned into errors, or
extra strictness LLVM applies. Where the fix is trivial — a missing `int` in an
implicit declaration, say — fix the source rather than silencing the warning.
Silence only what cannot be fixed.

## Darwin specifics

The Darwin support is ported from nixpkgs at
`04d294a46080bab12cb340e8a1d7f8283768b91b`, and it supports **aarch64-darwin
only** — there are no Intel bootstrap files upstream.

### Names that moved

Several attributes differ from their nixpkgs spellings:

| Upstream attribute | corepkgs attribute |
| --- | --- |
| `darwin.binutils` | `binutils` |
| `darwin.binutils-unwrapped` | `binutils.unwrapped` |
| `darwin.binutilsNoLibc` | `binutils.noLibc` |
| `darwin.libffi` | `libffi` |
| `darwin.libpcap` | `libpcap.apple` |
| `darwin.locale` (locale data) | `locale.data` |

`aliases/nixpkgs.nix` provides the compatibility names — `libffiReal`,
`libiconvReal` and the former flat binutils names among them — and
`aliases/darwin.nix` defines the `darwin` namespace as a view whose packages point
at the implementations above. Set `config.aliases.nixpkgs = false` to turn those
names off. Removed releases such as `libffi_3_3` still throw, as do legacy SDK
stubs and packages in the compatibility namespace that were never ported.

### Choosing an implementation

`libffi.real` selects upstream and `libffi.darwin` selects Apple's.
`libiconv.real` selects upstream libiconv. `locale` stays the platform-selected
command from `unixtools`, with its data at `locale.data`.

Platform selection lives in a short `default.nix` within each family, with the
implementations in `generic.nix` and `darwin.nix`. SDKs are available as
`apple-sdk`, `apple-sdk_14`, `apple-sdk_15` and `apple-sdk_26`.

### Design goals

Two goals are worth stating explicitly, because they shape the port:

The standard environment should build **with sandboxing enabled** on Darwin. A
package may need a `sandboxProfile` to build, but building the stdenv itself
should not require turning the sandbox off.

The output should depend only **weakly on the bootstrap tools**. Historically
Darwin required updating the bootstrap tools before the stdenv's LLVM could move.
By not depending on a specific version, LLVM can be updated simply by bumping
`llvmPackages` in `top-level.nix`.

### What is not verified

The evaluation checks cover the imported packages, the bootstrap generator and
its self-test, a stdenv built with fresh bootstrap files, compiler identity, SDK
overrides, and the LLVM variant interface. They do **not** execute Darwin
binaries, so they do not establish that the full native bootstrap builds.

Native validation means building `stdenv` and `freshBootstrapTools.test` on an
`aarch64-darwin` builder. Linux-to-Darwin cross builds are excluded by upstream's
`cctools` platform metadata. The portable helpers `sigtool`, `pbzx` and `dumpnar`
do build on Linux.

Xcode keeps upstream's `requireFile` behaviour; the SDK and bootstrap do not
require the proprietary Xcode download.
