# Introduction

corepkgs is the package set behind Ekala: the common development concerns a
nixpkgs fork needs, kept deliberately narrower than nixpkgs itself. It supplies
the stdenv, the compilers and interpreters, the language ecosystems, and the
module-system behaviour that everything else builds on.

This documentation is for people working *in* corepkgs — packaging a new
version, fixing a failed build, or deciding whether a change belongs here.

## Where to start

If you are updating a package and the build broke, [Common Build
Issues](common-issues/README.md) is a set of failure modes with the fix beside
each one. Most version bumps fail in one of those ways.

If you are wondering why something behaves differently here than it does in
nixpkgs, [Corepkgs vs. Nixpkgs](corepkgs-vs-nixpkgs.md) lists the deliberate
divergences and the reasoning behind them.

## How this repository is organised

Packages live where their attribute path says they do: `pkgs.vim` is at
`pkgs/vim`, and `python3.pkgs.requests` is at `python/pkgs/requests`. A file's
location is its identity, so a package is found by reading its path rather than
by searching for it.

## Guiding principles

The decisions recorded in these pages follow from a few standing preferences.
Explicit beats implicit, intuitive beats pedantic, and good defaults beat assumed
configuration. Automation beats manual work, and updating a package should stay
boring.
