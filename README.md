# JsVul: A function-level dataset of vulnerable and fixed source code in JavaScript and TypeScript

JsVul is a curated, function-level vulnerability dataset designed for the JavaScript and TypeScript ecosystems.
Aggregated from seven major sources (CrossVul, CVEFixes, JS Vulnerability Dataset, OSSF CVE benchmark,
SecBench.JS, OSV, and NVD), it supports the training of machine learning models for automated vulnerability
detection.

Unlike generic multi-language datasets, JsVul utilizes a language-specific pipeline to ensure high data quality.
The curation process includes:

* Noise Filtering: Removal of minified code, test files, and non-semantic cosmetic edits.
* Syntax Normalization: Application of ESLint and Prettier to standardizes code structure.
* Rigorous Deduplication: Multi-stage filtering at the file, commit, and function levels.

This repository holds the dataset of JsVul version 1.0.0, `js_vul.zip` on Zenodo
([doi 10.5281/zenodo.18195839](https://doi.org/10.5281/zenodo.18195839)). In this repository you will find:

* The labeled functions, in chronologically sorted JSON Lines files: **train.jsonl**, **val.jsonl** and
  **test.jsonl**.
* The changes from the original dataset (the functions kept for taint analysis with jelly-taint) in
  **DIFF_WITH_ORIGINAL.md**, with what each of its numbers counts.

## Why there is no code here

JsVul holds functions, not programs: a line is the text of one function, with the repository, commit and file it
comes from (`project`, `sha`, `file`). There is no package, no test and no exploit in it, so there are none in this
repository either. jelly-taint fetches and installs the code itself, the first time it analyzes a case, into folders
of this repository that `.gitignore` leaves out:

* `repos/<owner>__<repo>@<sha>/`: the repository at the vulnerable commit, fetched alone from GitHub
  (`git fetch --depth 1 origin <sha>`), with the production dependencies of the vulnerable file's package installed
  by pnpm. `fixed/` holds the fixing commits in the same way.
* `js-function-extractor/`: JsVul's own function extractor (github.com/jsvul/js-function-extractor). jelly-taint runs
  it on the original file to find the function's lines there, as JsVul's `loc` are lines of a copy that JsVul
  reformatted with ESLint and Prettier.
* `edited.txt`: the files jelly-taint changed in a repository so that pnpm could install it, one change per line.

The code isn't committed here: it is on GitHub at those commits, under its projects' own licenses, and it is large
(on our server, the vulnerable commits take about 25 GB with their dependencies installed).

There is no exploit to run either, so jelly-taint judges a case statically. Jelly analyzes the vulnerable file's
package, with the arguments of the package's exported functions as taint sources besides its usual ones, and a
vulnerable function is found when jelly reports a sink of the case's class (command injection, code injection, path
traversal, prototype pollution or ReDoS) inside it. jelly-taint's `benchmarks/jsvul.md` explains each step and why.

## The records

Each line is one function:

1. `id` (string): `[github_repo]::[commit_hash]::[file_path]::[start_line]::[start_column]`.
2. `paired_id` (string, optional): the `id` of the corresponding vulnerable or fixed counterpart, if applicable.
3. `project`, `sha`, `file` (string): the repository name, the commit hash and the relative file path. A vulnerable
   function's commit is the one before the fix, and its fixed counterpart's is the fixing commit.
4. `loc` (object): the function's `start_line`, `start_column`, `end_line` and `end_column`, in the files as
   formatted with ESLint and Prettier.
5. `body` (string): the source code of the function.
6. `label` (int): 1 for vulnerable, 0 for non-vulnerable.
7. `name` (string, optional): the function name.
8. `cwe` (string array, optional): Common Weakness Enumeration (CWE) identifiers.
9. `cve`, `ghsa`, `snyk`, `other` (string array, optional): vulnerability identifiers from NVD, GitHub Security
   Advisories (GHSA), Snyk, or other sources.
10. `publish_time` (object, optional): the publication date (`year`, `month`, `day`).

## Credit and license

JsVul is by Tamás Viszkok and Péter Hegedűs:

* Tamás Viszkok and Péter Hegedűs, *A Function-level Dataset of Vulnerable and Fixed Source Code in JavaScript and
  TypeScript*, arXiv 2609.38012 (2026).
* Tamás Viszkok and Péter Hegedűs, *JsVul: A function-level dataset of vulnerable and fixed source code in
  JavaScript and TypeScript*, version 1.0.0, Zenodo (2026), https://doi.org/10.5281/zenodo.18195839.
* The code that made it: https://github.com/jsvul/jsvul.

JsVul is licensed under the [Creative Commons Attribution 4.0 International license](https://creativecommons.org/licenses/by/4.0/)
(CC BY 4.0), and so is this repository.
