# Core-pkgs (WIP)

This repository is meant to be the provider of most common
development concerns for a nixpkgs fork. There should
be a high degree of scrutiny and quality put into the nix
expressions in this repository, as it will impact the most
use cases.

## Major differences from Nixpkgs

See [Major differences document](./docs/major-differences-nixpkgs.md).

## Package criteria

At a very high level, corepkgs is intended to include:
- Stdenv
- Compilers, interpreters, and toolchains
  - Common language ecosystem tools (e.g. popular linters, package managers) are included as well
- Logic around using overlays and most package scopes
- Ecosystems necessary system creation (e.g. systemd)
- And their dependencies

The goal is to allow for corepkgs to be a viable platform for people wanting
to do development and software deployments without the breadth of user tools
and other nicities. This reduced scope should allow for updates to be applied
more frequently and cause less rebuild churn than something the size of nixpkgs.

## Guiding design principles

These are a set of guiding principles when making packaging or process decisions.
Generally, this will cause divergence from Nixpkgs.

- Explict over implict
- Intuitive over pedantic
- Good defaults over assumed configuration
- Automation over manual
- Fun over drudgery

## Structure

```
build-support # Fetchers, shell hooks, and nix utilities
pkgs/         # Subdirectories are automatically imported to pkgs
  linux/      # Linux related packaging
python/       # Python related packaging
  pkgs/       # Directory for python package set, automatically imported
perl/         # Perl related packaging (interpreter) and packages
pkgs-many/    # Multi-version packages (java, nodejs, php, etc.)
top-level.nix # Overlay for specifying overrides at `pkgs` scope
default.nix   # Entry point for people to import
```

## Documentation

The documentation published for this repository is authored in markdown under `docs/` and
committed as a validated artifact in `docs/.interchange/`. Both halves are gated: a page edited
without regenerating its artifact fails, and so does an artifact edited by hand.

```bash
nix develop .#default -c bash scripts/docs-pipeline.sh --write    # regenerate the artifact
nix develop .#default -c bash scripts/docs-pipeline.sh --check    # validate
```

See [`scripts/README.md`](./scripts/README.md#docs-pipeline) for the authoring and regeneration
workflow, and [`docs/major-differences-nixpkgs.md`](./docs/major-differences-nixpkgs.md) for the
documentation itself.

## Binary cache

*WARNING*: This is a personal server, and should be considered untrusted

```
substituters = https://ekala-corepkgs.cachix.org
trusted-public-keys = ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w=
```

### Consuming this repository: re-declare the cache

`nixConfig` is **not inherited across a flake input or an `npins` pin**, so a repository that
consumes corepkgs does not get these substituters automatically and will build the package set
from source instead of substituting it. Re-declare both keys in the consumer's own `flake.nix`:

```nix
nixConfig = {
  extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
  extra-trusted-public-keys = [ "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w=" ];
};
```

This applies to the docs tooling too, and there it is measurable rather than theoretical:
`mystmd` is on `cache.nixos.org`, but the `content-format` validator is on **neither**
`cache.nixos.org` nor this cache unless CI has pushed it. A consumer that pins this repository
and does not re-declare the cache builds the validator from source on every CI run.

### Populating the cache

CI pushes to it, in all three jobs, through `cachix/cachix-action` with
`pushFilter` limited to what the jobs produce. The step is **skipped** when the
`CACHIX_AUTH_TOKEN` secret is absent, so the workflow is green on a fork without credentials and
begins populating the cache as soon as the secret is added.

### The pinned content-format input is private

The `ekala-org` flake input (the validator) lives in a private repository. A public fork's runner
cannot fetch it, so the `docs` job fails at flake evaluation — `program 'git' failed with exit
code 128` — before the gate runs. The `docs` job authenticates through a **`FORMAT_ARTIFACT_TOKEN`
secret** when one is set and skips that step when it is not, so the failure is attributable. This
is dev tooling only; it does not affect `lint` or `eval`, which pass without it.
