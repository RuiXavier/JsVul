# Differences from the original JsVul dataset

This repository holds the JsVul dataset of vulnerable and fixed JavaScript and TypeScript functions, prepared for
taint analysis with jelly-taint (`benchmarks/` of github.com/cs-au-dk/jelly-taint, where it is the JsVul benchmark).
The original dataset is `js_vul.zip` of JsVul version 1.0.0 on Zenodo (doi 10.5281/zenodo.18195839, MD5
`087fb7cfa213bde26135bae7874efe7f`), the first commit of this repository (`4c88872`): 21,901 functions, 2,039 of
them vulnerable. This repository differs from it in one way: it holds only the vulnerable functions of a CWE that
jelly-taint's taint analysis is evaluated on, and their fixed versions. It holds 1,182 functions, 714 of them
vulnerable, from 681 vulnerable commits. Every function kept is the line of the original as it is, in the same
file (`train.jsonl`, `val.jsonl` or `test.jsonl`) and in the same order.

## 1. Kept functions

- A vulnerable function (`label` 1) is kept when one of its `cwe` is in one of the five classes of jelly-taint's
  benchmarks, the categories of SecBench.js (`CWE_CLASSES` in jelly-taint's
  `benchmarks/dataset_builders/benchmark_cases.py`; `benchmarks/cwe-classes.md` there compares them with MITRE's
  hierarchy):

  | class | CWEs |
  | --- | --- |
  | code injection | CWE-94, CWE-95, CWE-96, CWE-97, CWE-1336 |
  | command injection | CWE-77, CWE-78, CWE-88, CWE-624, CWE-917 |
  | path traversal | CWE-22 to CWE-40, CWE-59, CWE-61, CWE-62, CWE-64, CWE-65, CWE-73, CWE-114, CWE-1386 |
  | prototype pollution | CWE-471, CWE-915, CWE-1321 |
  | ReDoS | CWE-400, CWE-730, CWE-1333 |

  714 of the 2,039 are. The other 1,325 are removed: 560 of XSS (CWE-79, CWE-80, mostly browser code), and 765 of
  other CWEs (CWE-200 74, CWE-20 57, CWE-284 48, CWE-918 46, CWE-1021 46, CWE-352 42, CWE-89 33, CWE-601 26, ...;
  18 have no CWE).
- The fixed version of a kept function (its `paired_id`, `label` 0, in the fixing commit) is kept: 468 of them.
  The other 19,394 functions of `label` 0 are removed.
- jelly-taint makes one case of each vulnerable commit (a `project` and `sha`): 681 cases.
