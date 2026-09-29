{
  description = "Core packages flake";

  inputs = {
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-lib.url = "github:ekala-project/nix-lib";
    # The content-format artifact, consumed as a pinned input (docs/dag/pr-dag.json ->
    # ContentFormat). The ref is explicit because `github:` URL grammar cannot express a
    # branch containing a slash — it parses the remainder as a PATH — and the revision is
    # recorded in flake.lock either way, so the read is a fixed commit.
    #
    # This input is DEV TOOLING only: the artifact's validator is not packaged into this
    # repository's package set, because a repository does not need it to build its packages.
    ekala-org.url = "git+https://github.com/ekala-project/ekala-org?ref=refs/heads/node/format-artifact";
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
