# Differences from the original JsVul dataset

This repository holds JsVul's vulnerable commits as cases for taint analysis with jelly-taint (`benchmarks/` of
github.com/cs-au-dk/jelly-taint, where it is the JsVul benchmark): 202 cases, each the code of a vulnerable commit's
package, how to install it, the files an analysis starts from, and its vulnerabilities with the native calls that
are their sinks, in the format of Wenyuan Xu's jelly-taint-benchmarks (`SCHEMA.md`). The original dataset is
`js_vul.zip` of JsVul version 1.0.0 on Zenodo (doi 10.5281/zenodo.18195839, MD5
`087fb7cfa213bde26135bae7874efe7f`), the first commit of this repository (`4c88872`): 21,901 functions, 2,039 of
them vulnerable. The cases come from it in three steps:

| step | result | section |
| --- | --- | --- |
| this repository filtered JsVul's function records | 518 vulnerable commits | 1 |
| jelly-taint-benchmarks made a case of each commit of the three injection classes, and reviewed every vulnerability by hand | 201 cases | 2 |
| this repository holds those cases, with one more and a few changes | 202 cases | 3 |

Until 2026-11-16 this repository held JsVul's function records themselves (`train.jsonl`, `val.jsonl`,
`test.jsonl`), and later commits corrected their labels and classes (2026-11-12 and 2026-11-14). That history, and
this file as it described it, are in the repository's git history (commit `e7f2cc6`).

## 1. From JsVul's functions to 518 vulnerable commits

This file at commit `4cce2fc` describes each step, with every case.

- **Kept functions:** the vulnerable functions (`label` 1) with a CWE of the five classes of jelly-taint's
  benchmarks, and their fixed versions: 714 of the 2,039, in 681 vulnerable commits.

  | class | CWEs |
  | --- | --- |
  | code injection | CWE-94, CWE-95, CWE-96, CWE-97, CWE-1336 |
  | command injection | CWE-77, CWE-78, CWE-88, CWE-624, CWE-917 |
  | path traversal | CWE-22 to CWE-40, CWE-59, CWE-61, CWE-62, CWE-64, CWE-65, CWE-73, CWE-114, CWE-1386 |
  | prototype pollution | CWE-471, CWE-915, CWE-1321 |
  | ReDoS | CWE-400, CWE-730, CWE-1333 |

- **Removed projects:** 3, whose repositories are gone from GitHub (soontao/cycle-import-check,
  turistforeningen/node-im-metadata and node-im-resize).
- **Removed overlaps:** the 160 vulnerable commits that are also cases of jelly-taint's other two benchmarks,
  SecBench.js and VulcaN (Wenyuan Xu's versions): the same advisory id, and the same vulnerable file but for
  whitespace and comments (150, on 2026-10-30), or the same package and file under another advisory id (10, on
  2026-11-02).

That left 912 functions, 547 of them vulnerable, from 518 vulnerable commits.

## 2. jelly-taint-benchmarks' cases

Wenyuan Xu's jelly-taint-benchmarks (github.com/wyxu95/jelly-taint-benchmarks) holds SecBench.js, VulcaN and JsVul
in one format. Its JsVul cases are made from this repository's 518 vulnerable commits, as they were at commit
`4cce2fc` (its `DIFF_WITH_ORIGINAL.md`, sections 4 and 5).

**The cases (241, one per commit of the three injection classes, one vulnerability each):**

- **Code:** the vulnerable commit fetched from GitHub, as `package/`: the folder of the package that holds the sinks
  (for a case in a monorepo, that package's folder, with the packages of the same repository it depends on in
  `package/node_modules/<name>`). Its production dependencies are installed with
  `pnpm install --prod --ignore-scripts`, from the repository's own lock file where it has one (`pnpm import`).
  `fixed.diff` holds the fixing commit's change to the package's folder.
- **Sinks:** a function JsVul labelled is followed down, through the package and its dependencies, to the native
  calls that the attacker's value reaches (`fs.*`, `child_process.*`, `eval`, `Function`, `vm.*`, `require` or
  `import()` of a computed name). After a jelly-taint run, 40 sinks were corrected to the call inside the function
  (195 reports inspected), a second review moved 24 vulnerabilities to the native calls, and 121 of the 182 whose
  sinks were still function ranges then got native calls. The others keep the function, because the case holds no
  Node.js call that the attack reaches. `originalSink` keeps the function.
- **Entry:** 116 cases name the source files an analysis starts from, as their package.json names build output
  that the repository doesn't hold, names none, or doesn't lead to the vulnerable code.

**The review** of every vulnerability (its `REVIEW_ANNOTATIONS.md` and `BORDERLINE.md`), under one threat model: the
attacker gives data to the package's exported API, its command line, or a network request to it. Of the 241 JsVul
cases, it removes 45 and adds 5:

| reason | cases |
| --- | --- |
| the flow is what the package is for: a server that runs its client's commands | win-cli-mcp-server@215f0cc |
| the class is outside the three: cross-site scripting, prototype pollution, IRC protocol injection, a crash, an upload on the PHP side | angular.js@1adf29a, angular.js@dd4ce50, dojox@5491eff, double-take@8e2728d, editor.js@cd06bfc, matrix-appservice-irc@062f3ac, matrix-appservice-irc@5fa23ed, mquery@34344fa, parse-server@0bb63d8, phpmyfaq@00c0409, wegia@2117691, wiki@98c04fe, xwiki-platform@f89c8f4 |
| the sink of the class is outside the package's JavaScript: a URL filter, a browser request, a Python backend, a desktop client, the caller's own write | broker@57c8741, broker@89380fd, gradio@67ddd40, jszip@1f631b0, misskey@2cd3fbf, nuxt@35c5f9f, raspap-webgui@e92835f, server@d936694, shescape@3f7da26, voila@e32a1e2 |
| the public entry passes the sink only constants or a schema-checked number | create-mcp-server-stdio@32e03b8, snyk-cocoapods-plugin@eb1737c |
| the value at the sink is the name of a function the caller passes | mixin-pro@9ca2934 |
| the commit already holds the fix; the commit before it is a case already | backstage@7422430, backstage@8cc5dd9, systeminformation@0be6fcd |
| the commit already holds the fix; replaced by the commit before it | changed-files@0102c07 and @7aaf10d (by changed-files@089842a), librechat@a23809f (by librechat@3c94ff2), node-degenerator@ccc3445 and @dc10ee9 (by node-degenerator@7ad1041), node-tar@9fc84b9 (by node-tar@52237e3), vitest@3826941 (by vitest@45085cf) |
| the vulnerable code is Python or PHP | cherrymusic@82ad793, django-s3file@03f6ff8, fides@993bf88, pimcore@deae04d, pimcore@fe155c8, rengine@41f6dbe |
| the vulnerable code is a browser userscript | pyload@213cd59, pyload@903c536 |

It also gives a vulnerability whose CWE names another of the three classes the class of the operation at its sinks
(`originalClass` keeps the CWE's), as json-logic-js@17e9fed (code injection), nodebb@40d73e2,
systeminformation@51c7698 and wiki-plugin-datalog@7228c97 (command injection); gives 6 vulnerabilities the class
stored command injection, where the attacker's data is first stored and runs later (actions/toolkit@90be12a,
anything-llm@2374939, changed-files@089842a, dive@bf69242, prisma language-tools@193cdb1, roo-code@10b2fb3); and
names the source of a vulnerability whose attacker data doesn't come through the API (`sourceKinds`: grunt@fdc7056
and npm@e300730 `file`, systeminformation@d93a0ce and @51c7698 `process-output`).

That leaves 201 JsVul cases, at jelly-taint-benchmarks' commit `beb5e9ce8` (2026-11-16).

## 3. This repository against jelly-taint-benchmarks

- **Only the JsVul cases:** the 201 folders of `cases/` whose `case.json` has `"from": ["jsvul"]`, as they are at
  `beb5e9ce8`, with every file its git tracks (the packages of the same repository in `package/node_modules/` too),
  and its `install.sh`, `check_case.py` and `SCHEMA.md`. `SCHEMA.md` also describes the SecBench.js and VulcaN
  cases, which aren't here.
- **No extras:** the `extra.tgz` archives (Git LFS) of 121 cases aren't here: binaries, media, `.gitattributes`
  files, and text files over 1 MB that are no code. JavaScript, TypeScript, JSON and other configuration files are
  in the repository whatever their size.
- **`install.sh`:** where corepack is missing (Node.js 25 and later), it runs a case's pnpm version with npx, and
  where no pnpm runs, npx's pnpm 9.15.9. `--fixed` leaves out the `pnpm-lock.yaml` files of `fixed.diff`: 56 of the
  diffs don't apply to their case's lock file, which was imported again after the diffs were made. A fixed
  version uses its case's installed dependencies, so its lock file doesn't matter. node-tesseract@f72e97b's
  `fixed.diff` also changes `test/test.png`, an extra, so its fixed version can't be made here.
- **mixin-pro@9ca2934, restored** (`cases/mixin-pro@9ca2934/`): the case as jelly-taint-benchmarks had it before it
  removed it (the parent of its commit `7fe09c35a`), with `"type": "library"` written as `"origin": "repository"`
  and `"role": "library"`, the fields that replaced it. jelly-taint's hand check found jelly's report at its `eval`
  to be a real attack route, the case comes from its upstream fix (`8bb3552`), and jelly-taint-benchmarks keeps
  thenify@3.3.0, a case of the same shape, because of its upstream fix.
- **sirv@d061616's entry** is `package/index.mjs` instead of `package`: its package.json names only build output
  that the repository doesn't hold (`build.js`, `build.mjs`), and its `files` field selects the type declarations
  (`index.d.*`), so an analysis that starts from the package's documented entry points finds no function of it.

jelly-taint's `benchmarks/jsvul.md` lists the cases and rules where its earlier hand check and jelly-taint-benchmarks'
review disagree.
