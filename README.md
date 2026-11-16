# JsVul cases for taint analysis

JsVul is a function-level vulnerability dataset for JavaScript and TypeScript (Tamás Viszkok and Péter Hegedűs,
version 1.0.0, [doi 10.5281/zenodo.18195839](https://doi.org/10.5281/zenodo.18195839)): the functions that
vulnerability fixes changed, gathered from seven sources (CrossVul, CVEfixes, the JS Vulnerability Dataset, the OSSF
CVE benchmark, SecBench.js, OSV and NVD), to train machine-learning vulnerability detectors.

This repository holds 202 of JsVul's vulnerable commits as cases for a taint analysis, the JsVul benchmark of
jelly-taint (`benchmarks/` of github.com/cs-au-dk/jelly-taint): each with the code of its package, how to install
it, the files an analysis starts from, and its vulnerabilities, each with the native calls that are its sinks. The
cases are those of Wenyuan Xu's jelly-taint-benchmarks, which reviewed every vulnerability by hand, in its format.
**DIFF_WITH_ORIGINAL.md** says how they come from JsVul, step by step, and where they differ from
jelly-taint-benchmarks.

## Files

* `cases/<name>@<commit>/`, one folder per vulnerable commit (**SCHEMA.md** describes every field):
  * `case.json`: the repository and commit, `entry` (the files or folders an analysis starts from), and the
    vulnerabilities, each with its advisory id, `class` (command injection, code injection, path traversal, or
    stored command injection), `cwe`, `sinks` (locations in the case's files), and `fix`: the fixing commit and
    the sinks' counterparts in the fixed version.
  * `package/`: the code of the package at the vulnerable commit (for a case of a monorepo, the folder of the
    package that holds the sinks, with the packages of the same repository it depends on in
    `package/node_modules/<name>`).
  * `install.json`: how to install `package/`: its folders, lock file, pnpm flags and pnpm version.
  * `fixed.diff`: the fixing commit's change to `package/`, when the fix is in it.
* `install.sh`: installs the cases' dependencies, and with `--fixed` makes each case's `fixed/` folder from
  `package/` and `fixed.diff`. `./install.sh -h` explains it.
* `check_case.py`: checks the `case.json` files against SCHEMA.md.

`.gitignore` leaves out what installing and analyzing make in the cases: `node_modules/` (but the packages of the
same repository, which are tracked: add them with `git add -f`), `.install/`, `fixed/` and the install logs.

## Install

```bash
./install.sh -j 4                          # every case; or name some: ./install.sh sirv@d061616 vite@5adbc53
./install.sh --fixed --no-deps sirv@d061616   # its fixed version, in cases/sirv@d061616/fixed/
```

pnpm installs each case's production dependencies from its lock file, without running install scripts. It needs
bash, tar, git and pnpm, or npx (Node.js).

## Credit and license

JsVul is by Tamás Viszkok and Péter Hegedűs:

* Tamás Viszkok and Péter Hegedűs, *A Function-level Dataset of Vulnerable and Fixed Source Code in JavaScript and
  TypeScript*, arXiv 2609.38012 (2026).
* Tamás Viszkok and Péter Hegedűs, *JsVul: A function-level dataset of vulnerable and fixed source code in
  JavaScript and TypeScript*, version 1.0.0, Zenodo (2026), https://doi.org/10.5281/zenodo.18195839.
* The code that made it: https://github.com/jsvul/jsvul.

The cases' format, sinks and review are Wenyuan Xu's jelly-taint-benchmarks (github.com/wyxu95/jelly-taint-benchmarks).

JsVul is licensed under the [Creative Commons Attribution 4.0 International license](https://creativecommons.org/licenses/by/4.0/)
(CC BY 4.0), and so are this repository's data and documents. The code in each case's `package/` is its project's,
at that commit, under that project's own license.
