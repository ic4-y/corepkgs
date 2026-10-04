# Introduction

corepkgs is the **core package set** behind Ekala: the common development
concerns a nixpkgs fork needs, kept **deliberately narrower than nixpkgs
itself**. Ekapkgs is the larger set, aggregating corepkgs and the satellite
ecosystems into one entrypoint; corepkgs is the base the rest builds on.

It supplies the stdenv, the compilers and interpreters, the language ecosystems,
and the module-system behaviour that everything else depends on.

The narrower scope is the point. A smaller surface means updates land more often
and cause **less rebuild churn** than something the size of nixpkgs.

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

## What's next

These pages serve two audiences. Almost everything downstream depends on which one
you are.

::::{grid}
:::{card} Use corepkgs
:link: ../using-corepkgs/README.md

As the base for a package set of your own, or as a flake input.
:::

:::{card} Work on corepkgs
:link: ../adding-packages/README.md

Adding a package, or fixing a build that broke. Start with the stdenv.
:::
::::
