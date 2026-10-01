# Introduction

corepkgs is the package set behind Ekala: the common development concerns a
nixpkgs fork needs, kept **deliberately narrower than nixpkgs itself**.

It supplies the stdenv, the compilers and interpreters, the language ecosystems,
and the module-system behaviour that everything else builds on.

The narrower scope is the point. A smaller surface means updates land more often
and cause **less rebuild churn** than something the size of nixpkgs.

## Two kinds of reader

These pages serve two audiences, and they are worth telling apart because almost
everything downstream depends on which one you are.

**If you are consuming corepkgs** — using it as the base for a package set of
your own, or building something that has to sit below the rest — start with
[Using corepkgs](../using-corepkgs/README.md). It covers the binary cache, a
flake that takes corepkgs as an input, and the same thing pinned with `npins`.

**If you are working in corepkgs** — packaging a new version, fixing a failed
build, or deciding whether a change belongs here — read [Stdenv](../stdenv/README.md)
first, then [Building Packages](../building-packages/README.md). The stdenv page
comes first because two of its defaults cause failures that look like something
else entirely.

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
