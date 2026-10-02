# Darwin

The Darwin support is ported from nixpkgs at
`04d294a46080bab12cb340e8a1d7f8283768b91b`. It supports **aarch64-darwin only** —
there are no Intel bootstrap files upstream.

## Updating LLVM

Update `llvmPackages` for Darwin in `top-level.nix` to match
`llvmPackages.latest`. This is timed against LLVM's release schedule: use the
spring release, and once `llvmPackages.latest` has been moved to match. If LLVM
has announced patch releases, wait until those land in nixpkgs before updating.

Then fix what breaks. Most breakage is additional warnings turned into errors, or
extra strictness LLVM applies. Where the fix is trivial — a missing `int` in an
implicit declaration, say — fix the source rather than silencing the warning.
Silence only what cannot be fixed.

:::{tip}
The stdenv depends on the bootstrap tools only **weakly**, so LLVM can be moved by
bumping `llvmPackages` alone. Historically, Darwin required the bootstrap tools to
be updated first.
:::

## Names that moved

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

## Choosing an implementation

`libffi.real` selects upstream and `libffi.darwin` selects Apple's.
`libiconv.real` selects upstream libiconv. `locale` stays the platform-selected
command from `unixtools`, with its data at `locale.data`.

Platform selection lives in a short `default.nix` within each family, with the
implementations in `generic.nix` and `darwin.nix`. SDKs are available as
`apple-sdk`, `apple-sdk_14`, `apple-sdk_15` and `apple-sdk_26`.

## What is not verified

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
