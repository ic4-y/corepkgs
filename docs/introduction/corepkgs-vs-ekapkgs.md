# Corepkgs vs. Ekapkgs

Ekapkgs is the larger set and the usual entrypoint: it aggregates corepkgs and
the satellite ecosystems (Haskell, Python, CUDA, R, Vim plugins) into one
package set. corepkgs is the **core** underneath — the nixpkgs fork everything
else builds on, kept deliberately narrower than nixpkgs itself.

The split is not a division of labour by topic; it is a division by **who owns
the interface**. corepkgs owns the base language: the stdenv, the compilers and
interpreters, the language ecosystems and the module system. Ekapkgs owns the
composition: it pins corepkgs and its satellites and re-exports one set, so a
consumer imports one repository rather than five.

## Which one do you want

| You are…                                   | Use       | Why                                                                     |
| ------------------------------------------ | --------- | ----------------------------------------------------------------------- |
| Building a package that needs the base set | corepkgs  | It is where the stdenv and the language ecosystems live — no aggregation |
| Consuming a package set for a system       | Ekapkgs   | One input, one `legacyPackages`, satellites included                    |
| Working on the stdenv or a compiler        | corepkgs  | That is the interface Ekapkgs does not own                              |
| Building an EkaOS system                   | Ekapkgs   | It provides `ekaosSystem`, the `nixosSystem` analogue                   |

## What each one owns

**corepkgs** is the base. Its scope is the common development concerns a nixpkgs
fork needs — see [Introduction](README.md) for the guiding principles and
[Corepkgs stdenv](../stdenv/README.md) for the environment everything builds in.
Package authors and stdenv work happen here; a change to the base lands here
first.

**Ekapkgs** is the composition. It aggregates corepkgs and the satellite
repositories and exposes the union as one `legacyPackages`, so most users
consume Ekapkgs rather than importing the individual ecosystem repositories
directly. It also carries `ekaosSystem`, the entrypoint for complete system
configurations.

## The dependency runs one way

Ekapkgs depends on corepkgs, never the reverse. That direction is what keeps the
two shippable on separate clocks: corepkgs can move on its own, and Ekapkgs picks
the new revision up when it re-pins. Nothing in corepkgs knows Ekapkgs exists —
which is why the base stays the smaller, faster-moving surface, and why the
comparison is [Corepkgs vs. Nixpkgs](corepkgs-vs-nixpkgs.md) rather than a
comparison against the layer above it.
