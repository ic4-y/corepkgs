# Introduction

corepkgs is the package set behind Ekala: the common development concerns a
nixpkgs fork needs, kept **deliberately narrower than nixpkgs itself**. It
supplies the stdenv, the compilers and interpreters, the language ecosystems,
and the module-system behaviour that everything else builds on.

The narrower scope is the point. A smaller surface means updates land more often
and cause **less rebuild churn** than something the size of nixpkgs.

This documentation is for people working *in* corepkgs — packaging a new version,
fixing a failed build, or deciding whether a change belongs here.

## Where to start

If you are updating a package and the build broke, [Common Build
Issues](common-issues/README.md) is a set of failure modes with the fix beside
each one. Most version bumps fail in one of those ways.

Start with **Obsolete Patches** if the error mentions a patch or a hunk. It is the
most common failure after a bump.

If you are wondering why something behaves differently here than it does in
nixpkgs, [Corepkgs vs. Nixpkgs](corepkgs-vs-nixpkgs.md) lists the deliberate
divergences and the reasoning behind them.

## How this repository is organised

A package lives where its attribute path says it does. `pkgs.vim` is at
`pkgs/vim`, and `python3.pkgs.requests` is at `python/pkgs/requests`.

**A file's location is its identity.** A package is found by reading its path
rather than by searching for it, so where you put a new package is a decision,
not a detail.

## Guiding principles

These are the standing preferences behind the decisions recorded in these pages:

- **Explicit over implicit.** A behaviour you can see in the expression beats one
  you have to know about.
- **Intuitive over pedantic.** Where the two conflict, the one that matches what
  a reader expects wins.
- **Good defaults over assumed configuration.** The common case should need no
  configuration at all.
- **Automation over manual.** If a step can be performed by a tool, it should not
  be a step a person remembers.
