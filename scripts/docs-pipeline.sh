#!/usr/bin/env bash
# THE DOCS PIPELINE — emit, stamp, and either WRITE the committed artifact or CHECK it.
#
# One script with two modes, the shape `scripts/gen-tokens.ts` and its `tokens-check` recipe
# already establish in the site repository, and for the same reason: the generator and the gate
# must be the same code or they drift. No flag writes the committed artifacts; `--check` emits
# afresh and compares, exiting non-zero on any difference.
#
# WHAT IS EMITTED
#
#   docs/.interchange/<slug>.json   one page, canonical mdast
#   docs/.interchange/manifest.json the page set
#
# The page-set manifest is required by design §6.2 and is not redundant: `raw.githubusercontent`
# cannot list a directory (R-10), so without it the site's clone cannot enumerate a page without
# the rate-limited tree API. It carries the slug, source path and file per page, so the page set
# is also a fact a reader can diff rather than a directory listing.
#
# WHY THE PAGES ARE STAMPED
#
# The emitter's artifact carries MyST's OWN `version` (3), a fact about the parser. `docs_format`
# is OURS and `parser_version` names the parser, and design §6.3 step 2 requires every emitted
# page to carry both so a source repository pinned to an older format fails in ITS OWN build
# rather than in the site's. `docs_format` is read from the PINNED VALIDATOR's `--version` and
# never restated here, because two homes for a version number drift.
#
# WHY THE FILES ARE NAMED BY SLUG
#
# Identity comes from where a page lives, not from its position or its filename. Left alone the
# emitter names the first toc entry `index.json` while its slug is `index`, so neither the file
# nor the slug says which page it is — and two pages that share a basename (twenty `README.md`
# files in this repository) collide outright. The slug is therefore derived from the source path,
# and the file is named after the slug.
#
# WHAT MAKES BOTH TAMPER DIRECTIONS FAIL
#
# Byte-equality between a FRESH emission and the committed artifact, over the canonical form
# (`validate --normalize` drops the per-run nanoid `key` and the mtime-derived export urls). So a
# page edited without regenerating fails, and a JSON edited by hand fails.
#
# Exit: 0 written (--write) or in sync (--check); 1 a difference / a finding / a stamp mismatch;
# 2 usage.

set -euo pipefail

MODE="check"
ROOT="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --write) MODE="write"; shift ;;
    --root) ROOT="${2:-}"; shift 2 ;;
    --help) sed -n '1,32p' "$0"; exit 0 ;;
    -*) echo "docs-pipeline: unknown flag '$1'" >&2; exit 2 ;;
    *) echo "docs-pipeline: unexpected argument '$1'" >&2; exit 2 ;;
  esac
done

cd "$ROOT"

EMITTED_DIR="_build/site/content"
COMMITTED_DIR="docs/.interchange"
MANIFEST="$COMMITTED_DIR/manifest.json"

# Both tools come from the devshell, so this MUST be invoked through it:
#     nix develop .#default -c bash scripts/docs-pipeline.sh [--check]
#
# They are checked rather than resolved by parsing anything, because this repository's own
# mkDevShell prints a BANNER to stdout when the shell is entered. A redirect or command
# substitution on the OUTSIDE of `nix develop -c` captures that banner — measured, and it
# silently corrupted the first committed artifacts.
for tool in validate myst jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "docs-pipeline: '$tool' is not on PATH — run through the devshell:" >&2
    echo "  nix develop .#default -c bash scripts/docs-pipeline.sh $([ "$MODE" = check ] && echo --check)" >&2
    exit 1
  }
done

# The format version the PINNED validator reports, and the emitter's own version. Read, never
# restated. `docs_format` is what the site checks; `parser_version` is provenance.
FORMAT_VERSION="$(validate --version | sed -E 's/^content-format ([0-9]+).*/\1/')"
PARSER_VERSION="$(myst --version | sed -E 's/^v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
case "$FORMAT_VERSION" in ''|*[!0-9]*) echo "docs-pipeline: could not read a format version from 'validate --version'" >&2; exit 1 ;; esac
[ -n "$PARSER_VERSION" ] || { echo "docs-pipeline: could not read a version from 'myst --version'" >&2; exit 1; }

# The slug: the source path under `docs/`, extension dropped, `/` flattened, and a `README` named
# for the directory it indexes. Unique across the page set, and independent of filename.
slug_of() {
  printf '%s' "$1" | sed -E 's#^/docs/##; s#\.md$##; s#/README$##; s#^README$#docs#; s#/#-#g'
}

echo "docs-pipeline: emitting from docs (format $FORMAT_VERSION, parser $PARSER_VERSION)"
rm -rf _build
myst build --site >/dev/null

# Canonical form + OUR stamps, keyed by slug. Reading the emitter's filenames is deliberate —
# they are what the toc produced; the slug is applied on top.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
slugs=()
for fresh in "$EMITTED_DIR"/*.json; do
  [ -f "$fresh" ] || continue
  location="$(jq -r '.location' "$fresh")"
  slug="$(slug_of "$location")"
  [ -n "$slug" ] || { echo "docs-pipeline: could not derive a slug from '$location'" >&2; exit 1; }
  if [ -e "$tmp/$slug.json" ]; then
    echo "docs-pipeline: two pages derive the same slug '$slug' — a page's identity must be unique" >&2
    echo "  $(jq -r '.location' "$tmp/$slug.json") and $location" >&2
    exit 1
  fi
  validate --normalize "$fresh" \
    | jq -c --argjson fv "$FORMAT_VERSION" --arg pv "$PARSER_VERSION" --arg slug "$slug" \
        '. + {slug: $slug, docs_format: $fv, parser_version: $pv}' > "$tmp/$slug.json"
  slugs+=("$slug")
done

[ "${#slugs[@]}" -gt 0 ] || { echo "docs-pipeline: the emitter produced no JSON — a comparison against nothing passes" >&2; exit 1; }

# The page set, sorted for a stable diff.
MANIFEST_JSON="$(
  for slug in "${slugs[@]}"; do
    jq -c --arg slug "$slug" '{slug: $slug, location: .location, file: ($slug + ".json")}' "$tmp/$slug.json"
  done | jq -cs --argjson fv "$FORMAT_VERSION" --arg pv "$PARSER_VERSION" \
    '{docs_format: $fv, parser_version: $pv, pages: sort_by(.slug)}'
)"

if [ "$MODE" = "write" ]; then
  mkdir -p "$COMMITTED_DIR"
  rm -f "$COMMITTED_DIR"/*.json
  for slug in "${slugs[@]}"; do cp "$tmp/$slug.json" "$COMMITTED_DIR/$slug.json"; done
  printf '%s\n' "$MANIFEST_JSON" | jq . > "$MANIFEST"
  echo "docs-pipeline: wrote ${#slugs[@]} page(s) and the manifest to $COMMITTED_DIR (format $FORMAT_VERSION)"
  exit 0
fi

fail=0
for slug in "${slugs[@]}"; do
  out="$COMMITTED_DIR/$slug.json"
  if [ ! -f "$out" ]; then
    echo "docs-pipeline: '$slug' is emitted but not committed at $out" >&2
    fail=1
    continue
  fi
  # THE STAMP CHECK, which names the repository that must rebuild. A stamp other than the pinned
  # format version means this repository emits against a format it is not pinned to, so THIS
  # repository regenerates — the point of carrying the version in the artifact (§6.3).
  committed_stamp="$(jq -r '.docs_format // "absent"' "$out")"
  if [ "$committed_stamp" != "$FORMAT_VERSION" ]; then
    echo "docs-pipeline: $slug.json carries docs_format=$committed_stamp but the pinned validator is format $FORMAT_VERSION — REPOSITORY corepkgs MUST REGENERATE its committed artifacts (nix develop .#default -c bash scripts/docs-pipeline.sh --write)" >&2
    fail=1
    continue
  fi
  if ! diff -q <(jq -c . "$tmp/$slug.json") <(jq -c . "$out") >/dev/null; then
    echo "docs-pipeline: $slug.json differs from the committed artifact — the page or the JSON changed without the other being regenerated" >&2
    fail=1
  fi
done

# The converse direction: a committed page no source emits is stale content the site would
# publish. Derived from the committed set, so a deleted page fails here rather than shipping.
for committed in "$COMMITTED_DIR"/*.json; do
  [ -f "$committed" ] || continue
  slug="$(basename "$committed" .json)"
  [ "$slug" = manifest ] && continue
  printf '%s\n' "${slugs[@]}" | grep -qx "$slug" || {
    echo "docs-pipeline: $slug.json is committed but no page emits it — stale artifact" >&2
    fail=1
  }
done

if [ ! -f "$MANIFEST" ]; then
  echo "docs-pipeline: no manifest committed at $MANIFEST" >&2
  fail=1
elif ! diff -q <(printf '%s\n' "$MANIFEST_JSON" | jq -S .) <(jq -S . "$MANIFEST") >/dev/null; then
  echo "docs-pipeline: manifest.json differs from the page set this emission produced — regenerate it" >&2
  fail=1
fi

# The vocabulary check, through the same tool: this is what makes "a document this site cannot
# render fails the SOURCE repository's build" true rather than aspirational.
if ! validate --kind docs --check "$EMITTED_DIR"/*.json >/dev/null 2>&1; then
  echo "docs-pipeline: the emitted page set has vocabulary findings:" >&2
  validate --kind docs --check "$EMITTED_DIR"/*.json 2>&1 | grep -E '^\s+\[' >&2 || true
  fail=1
fi

[ "$fail" -ne 0 ] && {
  echo "docs-pipeline: FAILED — regenerate with 'nix develop .#default -c bash scripts/docs-pipeline.sh --write' and commit the artifacts alongside the page" >&2
  exit 1
}

echo "docs-pipeline: OK — ${#slugs[@]} page(s) byte-equal to their committed artifacts, manifest in sync, stamped format $FORMAT_VERSION / parser $PARSER_VERSION, vocabulary clean"
