{
  description = "Core packages flake";

  inputs = {
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-lib.url = "github:ekala-project/nix-lib";
    # The content-format artifact, consumed as a pinned input (docs/dag/pr-dag.json ->
    # ContentFormat). Points at `main`: the staging branch this once named
    # (`node/format-artifact`) has been promoted and merged, so the artifact now has a
    # permanent, published home. The revision is recorded in flake.lock, so the read is a
    # fixed commit even though the ref is a branch.
    #
    # The `git+https` transport, NOT the `github:` scheme: this repository is PRIVATE while
    # the consuming fork is public (drift D15), so the GitHub API route answers 404 without a
    # token, while git resolves it through the local credential helper. The ref is explicit
    # because `github:` URL grammar cannot express a branch containing a slash.
    #
    # This input is DEV TOOLING only: the artifact's validator is not packaged into this
    # repository's package set, because a repository does not need it to build its packages.
    ekala-org.url = "git+https://github.com/ekala-project/ekala-org?ref=refs/heads/main";
    # The EMITTER (the parser). The format artifact ships the validator; the design also asks
    # for "one pinned parser", and this repository has none, so it is taken from a nixpkgs.
    #
    # It does NOT follow treefmt-nix's nixpkgs, and that is deliberate: measured, that tree
    # carries mystmd 1.3.18, which emits an artifact with NO `version` field and therefore is
    # not the wire shape this format models. The revision below carries mystmd 1.9.1.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      systems,
      nix-lib,
      treefmt-nix,
      ekala-org,
      nixpkgs,
      ...
    }:
    let
      forAllSystems = nix-lib.lib.genAttrs (import systems);
      mkTreefmt =
        pkgs:
        let
          fmt = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rs;
            programs.keep-sorted = {
              enable = true;
              includes = [
                "*.nix"
                "scripts/sync-with-nixpkgs/syncnix/config.py"
              ];
            };
          };
        in
        fmt.config.build.wrapper;
    in
    rec {
      legacyPackages = forAllSystems (
        system:
        import ./. {
          inherit system;
        }
      );
      formatter = forAllSystems (system: mkTreefmt legacyPackages.${system});

      # The content-format gate as a DERIVATION, so it is runnable hermetically and can be
      # wired into `nix flake check` — the CI job and the hooks invoke the same script through
      # the devshell, which is right for a contributor but not a build. Both the emitter and
      # the validator come from the same inputs the devshell uses, so this check and the CI job
      # cannot validate against different tools.
      checks = forAllSystems (system: {
        docs =
          nixpkgs.legacyPackages.${system}.runCommand "docs-content-format-check"
            {
              nativeBuildInputs = [
                nixpkgs.legacyPackages.${system}.bash
                nixpkgs.legacyPackages.${system}.jq
                ekala-org.packages.${system}.content-format
                nixpkgs.legacyPackages.${system}.mystmd
              ];
            }
            ''
              # The source tree, without the emitter's output directory: it is rebuilt here.
              cp -r ${self} src
              chmod -R u+w src
              cd src
              rm -rf _build
              bash scripts/docs-pipeline.sh --check
              touch $out
            '';
      });

      # The author-facing shell. It carries the pinned content-format validator so a writer
      # can run `nix develop -c validate --kind docs --check` from this repository, and it
      # takes its TOOLCHAIN from this repository's own pkgs rather than from the input —
      # so evaluating this shell never evaluates the input's outputs.
      devShells = forAllSystems (
        system:
        let
          pkgs = legacyPackages.${system};
        in
        {
          # `pkgs.mkDevShell` — the constructor the package set exposes, called the same way
          # the site repository calls it.
          default = pkgs.mkDevShell {
            # `nativeBuildInputs`, NOT `packages`: mkDevShell maps `packages` to
            # buildInputs, which land in HOST_PATH and are therefore invisible to
            # `nix develop`. Same reason the site repository does it this way.
            nativeBuildInputs = [
              # The validator, from the pinned artifact.
              ekala-org.packages.${system}.content-format
              # The emitter. From the nixpkgs pinned at the top of this file — NOT from
              # treefmt-nix's, whose mystmd (1.3.18) emits no `version` field. It is what
              # `docs-pipeline.sh` calls in both of its modes.
              nixpkgs.legacyPackages.${system}.mystmd
            ];
            shellHook = ''
              echo "content-format: run 'validate --kind docs --check <artifacts>'" >&2
            '';
          };
        }
      );
      nixConfig = {
        extra-substituters = [ "https://ekala-corepkgs.cachix.org" ];
        extra-trusted-public-keys = [
          "ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w="
        ];
      };
      lib = nix-lib // {
        mkFlake = import ./lib/mk-flake.nix;
        ekaosSystem = import ./ekaos;
      };
    };
}
