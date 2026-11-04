# Differences from the original JsVul dataset

This repository holds the JsVul dataset of vulnerable and fixed JavaScript and TypeScript functions, prepared for
taint analysis with jelly-taint (`benchmarks/` of github.com/cs-au-dk/jelly-taint, where it is the JsVul benchmark).
The original dataset is `js_vul.zip` of JsVul version 1.0.0 on Zenodo (doi 10.5281/zenodo.18195839, MD5
`087fb7cfa213bde26135bae7874efe7f`), the first commit of this repository (`4c88872`): 21,901 functions, 2,039 of
them vulnerable. This repository differs from it in three ways: it holds only the vulnerable functions of a CWE
that jelly-taint's taint analysis is evaluated on, and their fixed versions, 3 projects whose repository is gone are
removed, and 160 vulnerable commits that are also cases of jelly-taint's other two benchmarks, SecBench.js and
VulcaN, are removed (sections 3 and 4). It holds 912 functions, 547 of them vulnerable, from 518 vulnerable commits. Every function kept is the line of the original as it is, in the same
file (`train.jsonl`, `val.jsonl` or `test.jsonl`) and in the same order.

## The numbers

**Why only 2,039 of JsVul's 21,901 functions are vulnerable.** JsVul was made to train and test machine-learning
vulnerability detectors, which learn from non-vulnerable code as well. For each vulnerability fix, JsVul took the
files the fixing commit changed, before and after the fix, and split them into functions (its paper, arXiv
2609.38012, section "Data Processing"):

- A function of a file before the fix that the fix changed is **vulnerable** (`label` 1): 2,039 functions. A function
  that the fix only moved or reformatted doesn't count.
- Every other function is **not vulnerable** (`label` 0): 19,862 functions. 1,342 of them are the **fixed versions**
  of vulnerable functions, the same function after the fix: a vulnerable function and its fixed version name each
  other in `paired_id`. The other 18,520 are functions of the same files that the fix didn't change.

The other 697 vulnerable functions have no fixed version in JsVul; its paper doesn't say why.

**Functions and cases.** JsVul counts functions; jelly-taint counts cases too. A **case** is one vulnerable commit (a
`project` and a `sha`): jelly-taint fetches the repository at that commit, installs it, and runs jelly on it once. A
fix can change several functions, so a case can have several vulnerable functions, and each is checked on its own:
jelly-taint's recall is the share of vulnerable functions with a report of the case's class inside them. Of the 518
cases here, 497 have one vulnerable function, 15 have two, 4 have three and 2 have four: 547 vulnerable functions.
Most have one because JsVul keeps a fix only when it changes exactly one function, or when the vulnerability's NVD
entry names the changed functions, or a file with only one of them (the paper's "onefunc" and "nvdcheck"). A project
can have several cases, other vulnerabilities fixed at other commits: the 518 cases come from 402 projects. Of the
518, 341 have the fixed version of every vulnerable function, 2 of only some of them, and 175 of none.

**Step by step:**

| | vulnerable functions | fixed versions | other functions | all functions | cases | projects |
| --- | --- | --- | --- | --- | --- | --- |
| JsVul 1.0.0 | 2,039 | 1,342 | 18,520 | 21,901 | 1,935 | 1,162 |
| only the CWEs of jelly-taint's five classes (section 1) | 714 | 468 | 0 | 1,182 | 681 | 528 |
| without the 3 projects gone from GitHub (section 2) | 711 | 468 | 0 | 1,179 | 678 | 525 |
| without 150 cases that are SecBench.js or VulcaN cases too (section 3) | 557 | 370 | 0 | 927 | 528 | 410 |
| without 10 more, under another advisory id (section 4) | 547 | 365 | 0 | 912 | 518 | 402 |

**The three files** are JsVul's split for machine learning, by the vulnerability's publication date: the oldest 80% of
the vulnerable functions (published up to November 2024) are in `train.jsonl`, the next 10% (up to May 2025) in
`val.jsonl` and the newest 10% (up to November 2025) in `test.jsonl`, each fixed version in the same file as its
vulnerable function. jelly-taint trains nothing and uses all three alike.

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

## 2. Removed projects

The repositories of 3 projects are gone from GitHub (checked on 2026-10-19 and 2026-10-30), so their commits can't
be fetched, and jelly-taint can't analyze them. Their 3 vulnerable functions are removed; none has a fixed version.

| project | vulnerable commit | file | CVE | CWE |
| --- | --- | --- | --- | --- |
| soontao/cycle-import-check | `3e0eb4fd05` | `src/file.ts` | CVE-2022-24377 | CWE-78 |
| turistforeningen/node-im-metadata | `049ce24dbb` | `index.js` | CVE-2019-10788 | CWE-78 |
| turistforeningen/node-im-resize | `499fe82028` | `index.js` | CVE-2019-10787 | CWE-78 |

## 3. Removed cases that are SecBench.js or VulcaN cases too

jelly-taint's other two benchmarks are SecBench.js and VulcaN, in Wenyuan Xu's versions
(github.com/Anemone95/SecBench.js and github.com/Anemone95/VulcaN). A vulnerable commit that is also one of their
cases is removed, with its functions and their fixed versions, so that the same case isn't analyzed, and its gaps
fixed, twice. It is the same case when it has the same package, the same version and the same vulnerability:

- **Same vulnerability:** it shares an advisory id (CVE, GHSA or Snyk) with the other case: the `cve`, `ghsa` and
  `snyk` of its functions, and the SecBench.js case's `package.json` (`id` and `links`) or the VulcaN review's
  `advisory`. 272 of the 678 vulnerable commits do. JsVul's own sources (`merged_data.zip`) aren't used: they say
  when a fixing commit came from SecBench.js, but not from which case, and they miss 54 that share an advisory id
  with a SecBench.js case. VulcaN isn't one of JsVul's sources, but OSV and NVD hold the advisories VulcaN is made
  from.
- **Same version:** the vulnerable file is the same at JsVul's commit and in the other case's package, whatever the
  version numbers say (JsVul's commit is the one before the fix, not a release). The other package's file is the
  one at the same path, or at the path without the repository's leading folders, for a package of a monorepo.
  Differences in whitespace and comments don't count; the comments are those Babel finds with jelly's parse
  options. For example, growl's `lib/growl.js` is the same in SecBench.js's growl 1.9.0 and at JsVul's commit
  `dc8aae046d`, whose `package.json` says 1.9.2.
- A vulnerable commit with vulnerable functions in several files stays (5 of the 272): SecBench.js checks one sink,
  and VulcaN one or a few, nearly always in one file, so the other files are code they don't check.

150 are the same case: 148 with whitespace alone, and tree-kit and axios because of the comments. Of the other 117,
the file differs in 95 (another version), and the package has no file at that path in 22 (a package that ships
built code, or a wrong advisory id). The comparison is against SecBench.js at `3b6fd475` and VulcaN at `68ead5222`.
jelly-taint's `./cli.py db jsvul-overlaps` (`jsvul_overlaps` in `benchmarks/dataset_builders/benchmark_cases.py`)
finds them. The 150 have 154 vulnerable functions and 98 fixed versions.

| project | vulnerable commit | the same SecBench.js and VulcaN cases |
| --- | --- | --- |
| 3rd-eden/useragent | `50be8cbd7e` | vulcan/312_GHSA-pjmx-9xr3-82qr |
| acstll/deep-get-set | `7c04be87cb` | secbench/deep-get-set_1.1.0, vulcan/GHSA-85cp-p426-42f5 |
| adaltas/node-csv-parse | `76d96e16b1` | vulcan/1171_GHSA-582f-p4pg-xc74 |
| adaltas/node-mixme | `fdeddcd96a` | vulcan/GHSA-79jw-6wg7-r9g4 |
| ahdinosaur/set-in | `a883c87157` | vulcan/GHSA-qr4p-c9wr-phr6 |
| aheckmann/gm | `7c7dd392d9` | secbench/gm_1.20.0, vulcan/54_GHSA-pjh3-jv7w-9jpr |
| algolia/algoliasearch-helper-js | `dff9e32bf1` | secbench/algoliasearch-helper_3.6.0 |
| angus-c/just | `f5549c99e7` | secbench/just-extend_3.0.0, vulcan/780_GHSA-675m-85rw-j3w4 |
| apollographql/apollo-server | `ce459ce979` | vulcan/917_GHSA-74cr-77xc-8g6r |
| ardalanamini/prototyped.js | `2ca3acf3f9` | secbench/prototyped.js_2.0.0 |
| ariabuckles/simple-markdown | `a52c2704eb` | vulcan/1147_GHSA-4xf9-pgvv-xx67 |
| asaianudeep/deep-override | `393135641f` | secbench/deep-override_1.0.0, vulcan/GHSA-v659-54cx-g4qr |
| aws/aws-sdk-js-v3 | `7e7feb162a` | secbench/aws-sdk-shared-ini-file-loader_1.0.0-rc.8 |
| axios/axios | `5bc9ea24dd` | secbench/axios_0.21.0 |
| b-heilman/bmoor | `57084c5527` | secbench/bmoor_0.8.11 |
| broofa/mime | `4a375abebf` | vulcan/535_GHSA-wrvr-8mpx-r7pp |
| browserify/static-eval | `ab81134a43` | vulcan/548_GHSA-5mjw-6jrh-hvfq |
| browserify/syntax-error | `05f2390cde` | vulcan/37_GHSA-5726-g6r9-5f22 |
| cedced19/fast-http | `a827da286c` | secbench/fast-http_0.1.3 |
| chaijs/pathval | `a1230184a3` | secbench/pathval_1.1.0 |
| chalk/ansi-regex | `a079ab2d30` | secbench/ansi-regex_4.1.0 |
| codemirror/codemirror5 | `1cb6de23c7` | secbench/codemirror_5.58.0 |
| codemirror/codemirror5 | `cdb228ac73` | secbench/codemirror_5.58.0 |
| commenthol/safer-eval | `1ff9411b40` | secbench/safer-eval_1.3.1, vulcan/1021_GHSA-r3x4-wr4h-pw33 |
| commenthol/safer-eval | `74e5bb845c` | vulcan/787_GHSA-hgch-jjmr-gp7w |
| commenthol/serialize-to-js | `a1e8140ed1` | secbench/serialize-to-js_0.5.0, vulcan/313_GHSA-mm62-wxc8-cf7m |
| cronvel/tree-kit | `c2b9c91884` | secbench/tree-kit_0.6.1 |
| crysalead-js/extend-merge | `d99271d267` | secbench/extend-merge_1.0.5 |
| d3/d3-color | `017a46380f` | secbench/d3-color_2.0.0 |
| dckt/localhost-now | `f12b069492` | vulcan/582_GHSA-2gjg-5x33-mmp2 |
| debug-js/debug | `47747f329f` | vulcan/534_GHSA-gxpj-cx7g-858c |
| deoxxa/dotty | `8e157c2cd0` | vulcan/GHSA-f5c9-x9j6-87qp |
| dodo/node-slug | `fcb67e2f63` | secbench/slug_0.9.1, vulcan/537_GHSA-jxqq-cqm6-pfq9 |
| domharrington/node-gitlog | `256a9617fc` | vulcan/GHSA-67mm-m3wx-j7fr |
| dominictarr/libnested | `d028a1b0f2` | secbench/libnested_1.5.0 |
| doowb/set-getter | `dc2569055e` | secbench/set-getter_0.1.0, vulcan/GHSA-jv35-xqg7-f92r |
| dreamerslab/node.extend | `91713698d8` | vulcan/781_GHSA-r96c-57pf-9jjm |
| dynamoose/dynamoose | `329d59d70b` | vulcan/GHSA-rrqm-p222-8ph2 |
| eggjs/scripts | `08f8ea9429` | vulcan/694_GHSA-c9j3-wqph-5xx9 |
| expressjs/method-override | `5a7d6a1f2f` | vulcan/538_GHSA-qx2f-477c-35rq |
| expressjs/morgan | `eb1968ac69` | vulcan/736_GHSA-gwg9-rgvj-4h5j |
| fabiocaccamo/utils.js | `457473e72f` | secbench/fabiocaccamo-utils.js_0.17.0 |
| facebook/create-react-app | `22f46a8d5d` | secbench/react-dev-utils_11.0.0, vulcan/GHSA-5q6m-3h65-w53x |
| facebook/react-native | `166a5ddf88` | secbench/react-native_0.63.0-rc.0 |
| fagbokforlaget/pdfinfojs | `379c0e14db` | vulcan/643_GHSA-3pxp-6963-46r9 |
| fgribreau/node-truncate | `99a75f40be` | secbench/truncate_2.0.0 |
| firebase/firebase-js-sdk | `ab0f643571` | vulcan/GHSA-fpm5-vv97-jfwg |
| geddy/geddy | `75a7a9f2b5` | vulcan/10_GHSA-333x-9vgq-v2j4 |
| guymograbi/kill-by-port | `16dcbe264b` | secbench/kill-by-port_0.0.1, vulcan/GHSA-mm4f-47ch-f7hx |
| hapijs/inert | `b9cf3bd96c` | vulcan/14_GHSA-g4xp-36c3-f7mr |
| hapijs/nes | `71e9232bb8` | vulcan/331_GHSA-3pwh-5mmc-mwrx |
| henrytseng/hostr | `5827ba48fd` | vulcan/303_GHSA-xqqr-p362-6rmc |
| herber/hekto | `a3d942d839` | vulcan/586_GHSA-x26f-26qw-hhhx |
| hlfshell/controlled-merge | `7c0e7cb82d` | vulcan/GHSA-5pg7-v24c-9rp9 |
| hoperyy/get-npm-package-version | `52797864df` | secbench/get-npm-package-version_1.0.6 |
| immerjs/immer | `d75de7031c` | vulcan/GHSA-9qmh-276g-x5pj |
| irrelon/irrelon-path | `bfbaddfbef` | vulcan/GHSA-j7cg-h9v9-6vqp |
| iximiuz/node-diskusage-ng | `53c5055065` | secbench/diskusage-ng_0.2.6 |
| jarofghosts/glance | `7e69a55392` | vulcan/590_GHSA-2x4q-6jfv-8h9h |
| jas-/node-libnmap | `49b72239b1` | secbench/libnmap_0.4.11, vulcan/719_GHSA-7g2w-6r25-2j7p |
| jashkenas/underscore | `ef646ccbbb` | secbench/underscore_1.13.0-0, vulcan/GHSA-cf4h-3jhx-xvhq |
| javascipt/effect | `f37c618f17` | secbench/effect_1.0.4 |
| jaywcjlove/colors-cli | `77ac683e2a` | secbench/colors-cli_1.0.25 |
| jefferyhus/es6-crawler-detect | `91adf5234f` | vulcan/GHSA-jxg6-fhwc-9v9c |
| jonschlinkert/assign-deep | `edab79f1fe` | secbench/assign-deep_1.0.0 |
| jonschlinkert/assign-deep | `f6cba02d11` | vulcan/579_GHSA-xcvv-84j5-jw9h |
| jonschlinkert/defaults-deep | `aef804bf3e` | vulcan/581_GHSA-cqp5-m4pq-gfgp |
| jonschlinkert/merge-deep | `7be7e50163` | vulcan/580_GHSA-9g9w-hmvj-5h57 |
| jonschlinkert/mixin-deep | `7705bdf88f` | secbench/mixin-deep_1.3.0, vulcan/578_GHSA-3mpr-hq3p-49h9 |
| josdejong/ducktype | `676c6dc616` | secbench/ducktype_1.2.0 |
| josdejong/mathjs | `4a9378789a` | vulcan/552_GHSA-vx5c-87qx-cv6c |
| josdejong/mathjs | `8d2d48d81b` | vulcan/551_GHSA-pv8x-p9hq-j328 |
| josdejong/mathjs | `a2858e266a` | secbench/mathjs_7.4.0 |
| juanfran/gulp-scss-lint | `e74f2bc98d` | vulcan/GHSA-g4hj-r7r3-9rwv |
| juliangruber/brace-expansion | `265f6cd658` | secbench/brace-expansion_1.1.6, vulcan/338_GHSA-832h-xg76-4gv6 |
| justmoon/node-extend | `a689700740` | secbench/extend_3.0.1, vulcan/996_GHSA-qrmc-fj45-qfc2 |
| kevva/decompress | `74a462a139` | vulcan/1217_GHSA-qgfr-5hqp-vrw9 |
| knowledgecode/date-and-time | `73103a3d24` | secbench/date-and-time_0.14.1 |
| korynunn/list-n-stream | `87de3f1346` | vulcan/344_GHSA-23vf-5g53-hm9q |
| kriszyp/json-schema | `c52a27c653` | secbench/json-schema_0.3.0 |
| kylefarris/clamscan | `d474da7b89` | secbench/clamscan_1.2.0 |
| kyleross/windows-cpu | `da656c1a9d` | vulcan/336_GHSA-63m4-fhf2-cmf7 |
| lodash/lodash | `5a3ff73997` | vulcan/577_GHSA-fvqr-27wr-82fm |
| lodash/lodash | `ded9bc6658` | vulcan/GHSA-35jh-r3h4-6jhm |
| m-prj/m-log | `cbd69f368e` | secbench/m-log_0.0.1 |
| mafintosh/is-my-json-valid | `314a36f98c` | secbench/is-my-json-valid_2.20.1 |
| manuelstofer/json-pointer | `9b5ea8e3b2` | secbench/json-pointer_0.6.1 |
| markdown-it/markdown-it | `76469e83dc` | secbench/markdown-it_9.1.0 |
| mcollina/msgpack5 | `c279c34ea6` | vulcan/GHSA-gmjw-49p4-pcfm |
| micromatch/braces | `37934142c1` | vulcan/786_GHSA-g95f-p29q-9xw4 |
| minimistjs/minimist | `13c01a5327` | vulcan/1179_GHSA-vh95-rmgr-6w4m |
| mithriljs/mithril.js | `48e7fd1711` | vulcan/1094_GHSA-c3px-v9c7-m734 |
| mithunsatheesh/node-rules | `1b07c48336` | vulcan/1499_GHSA-8whr-v3gm-w8h9 |
| mjwwit/node-xmlhttprequest | `bf53329b61` | vulcan/GHSA-h4j5-c7cj-74xg |
| monsterkodi/sds | `24fbf50bf1` | secbench/sds_3.2.0, vulcan/1506_GHSA-cxm3-284p-qc4v |
| mout/mout | `2189378ed4` | secbench/mout_1.0.0 |
| muzzley/mobile-icon-resizer | `3e4dfe49b9` | secbench/mobile-icon-resizer_0.4.0, vulcan/317_GHSA-mxjr-xmcg-fg7w |
| naturalnode/natural | `7689c9aad4` | secbench/natural_5.1.0 |
| nescalante/urlregex | `d946be38e0` | secbench/urlregex_0.5.0 |
| nodeca/js-yaml | `59b6e76b71` | vulcan/788_GHSA-2pr6-76vf-7546 |
| nodee-apps/utils | `76f514ab39` | secbench/nodee-utils_1.2.2, vulcan/GHSA-p6jh-p7q8-pcrg |
| npm/fstream | `1e4527ffe8` | vulcan/886_GHSA-xf7w-r453-m56c |
| npm/ini | `738eca59d7` | secbench/ini_1.3.5 |
| npm/npm-user-validate | `cd7539362b` | secbench/npm-user-validate_1.0.0, vulcan/GHSA-xgh6-85xh-479p |
| nunnly/m-server | `3fcc6771fb` | secbench/m-server_1.4.0 |
| oliversalzburg/i18n-node-angular | `85ba51ac9d` | vulcan/80_GHSA-97gv-3p2c-xw7j |
| omphalos/crud-file-server | `833e7fcc2b` | vulcan/1003_GHSA-vfp9-gwrh-wq9g |
| outmoded/bassmaster | `83f02417be` | vulcan/1_GHSA-5j3g-jfq3-7jwx |
| parallax/jspdf | `c91995de97` | vulcan/GHSA-57f3-gghm-9mhc |
| pillarjs/resolve-path | `7330f71464` | vulcan/573_GHSA-62g9-6hw5-rwfp |
| pillarjs/send | `463d1c9226` | vulcan/32_GHSA-xwg4-93c6-3h42 |
| pjshumphreys/patchmerge | `cae81002f4` | secbench/patchmerge_1.0.0, secbench/patchmerge_1.0.1 |
| pocketly/node-sanitize | `6ddc0a0404` | secbench/sanitize_2.0.0 |
| postcss/postcss | `6f608a1059` | vulcan/GHSA-hwj9-h5mp-3pm3 |
| prahladyeri/http-live-simulator | `8e85a1be56` | vulcan/772_GHSA-7c9w-qmrq-ff8r |
| prisma/prisma | `7829289fd7` | vulcan/GHSA-pxcc-hj8w-fmm7 |
| rawiroaisen/node-ini-parser | `e6ea77283a` | secbench/ini-parser_0.0.2, vulcan/1508_GHSA-96r7-mrqf-jhcc |
| remarkablemark/html-dom-parser | `e9878da6e7` | secbench/html-dom-parser_0.1.2 |
| ronomon/opened | `33c2dfb8fd` | vulcan/GHSA-fg5w-w99f-rj6w |
| sharpred/deephas | `105a15b0bc` | secbench/deephas_1.0.5 |
| sindresorhus/decamelize | `1847982185` | vulcan/308_GHSA-q5c4-39f5-m68j |
| sindresorhus/normalize-url | `b98fe7e378` | secbench/normalize-url_6.0.0 |
| skoranga/node-connection-tester | `7d7b7112d4` | secbench/connection-tester_0.2.0 |
| skoranga/node-dns-sync | `b748fe77a8` | secbench/dns-sync_0.1.0, vulcan/153_GHSA-jcw8-r9xm-32c6 |
| skratchdot/object-path-set | `48b246ee10` | secbench/object-path-set_1.0.0 |
| ssnau/killport | `5268f23ea8` | secbench/killport_1.0.1, vulcan/GHSA-fc42-h7q4-qp8h |
| strikeentco/set | `2e246ec3f4` | secbench/strikeentco-set_1.0.0 |
| thenables/thenify | `aa21cfb64f` | secbench/thenify_3.3.0 |
| tiaanduplessis/kill-port | `6963218ea7` | vulcan/966_GHSA-pmv6-gf98-p3r5 |
| tj/node-growl | `dc8aae046d` | secbench/growl_1.9.0 |
| tjatse/ansi-html | `99ec49e431` | secbench/ansi-html_0.0.7 |
| tojocky/node-printer | `7987544670` | vulcan/27_GHSA-5c8j-xr24-2665 |
| totaljs/framework | `1e1faeb20d` | secbench/total.js_3.4.6, vulcan/GHSA-6cf8-qhqj-vjqm |
| totaljs/framework | `79e84ada0a` | secbench/total.js_3.4.6, vulcan/GHSA-4449-hg37-77v8 |
| trentm/json | `8d3cf253e4` | vulcan/GHSA-3c6g-pvg8-gqw2 |
| tritondatacenter/node-sshpk | `4d01aede23` | secbench/sshpk_1.13.1, vulcan/606_GHSA-2m39-62fm-q8r3 |
| unclechu/node-deep-extend | `9653940a75` | secbench/deep-extend_0.5.0, vulcan/612_GHSA-hr2v-3952-633q |
| vega/vega | `99c37e02a2` | secbench/vega-util_1.13.0, vulcan/GHSA-6hwh-rqwf-cxxr |
| vercel/serve | `ce95709c74` | vulcan/561_GHSA-q2qh-cgc2-qhr3 |
| victornpb/asciitable.js | `786348a188` | secbench/asciitable.js_1.0.2 |
| viking04/merge | `84dc0992b4` | secbench/viking04-merge_1.0.0 |
| vincentmorneau/apex-publish-static-files | `8d28fe8a9a` | secbench/apex-publish-static-files_2.0.0 |
| vvo/node-whereis | `b8b642b116` | secbench/whereis_0.4.0, vulcan/604_GHSA-wjr4-2jgw-hmv8 |
| wanasit/chrono | `3f294e0095` | secbench/chrono-node_2.2.3 |
| websockets/ws | `56f8062539` | vulcan/550_GHSA-5v72-xg48-5rpm |
| whitfin/dot-notes-js | `1c87f5e03b` | secbench/dot-notes_3.2.0, vulcan/GHSA-qr4m-jcvc-3382 |
| yargs/y18n | `61a8b9a4c7` | vulcan/GHSA-c4w7-xm78-47vh |
| yola/promisehelpers | `6e42c7bfe7` | secbench/promisehelpers_0.0.5, vulcan/GHSA-rj5f-7c8x-gjg4 |
| yuanqing/gulp-tape | `84830d193e` | vulcan/GHSA-x67x-98x7-wv26 |
| zjonsson/node-unzipper | `48bd69eaa3` | vulcan/680_GHSA-884w-698f-927f |

## 4. Removed cases that are SecBench.js or VulcaN cases under another advisory id

Section 3 finds a case only when it lists an advisory id that the other case lists too. But the advisories of one
vulnerability don't always name each other: an npm or Snyk advisory from the time and a CVE given years later to the
same fix, or a wrong id. 10 more vulnerable commits are such cases, found on 2026-11-02, against the same SecBench.js
and VulcaN commits:

- **Same package:** the vulnerable commit's repository, or the `name` in a `package.json` from the vulnerable file's
  folder up to the repository's root, is the repository or the name of a SecBench.js or VulcaN package. 179 of the
  528 vulnerable commits left by section 3 have one.
- **Same version:** the vulnerable file is the same as a file of the same name anywhere in that package, but for
  whitespace and comments, as in section 3: 20 vulnerable commits. 3 of them share an advisory id but have
  vulnerable functions in several files, and stay (section 3). Comparing with every file of that name in every
  SecBench.js and VulcaN package, whatever the package, finds no other, but requirejs's `require.js` inside
  VulcaN's jQuery, another vulnerability.
- **Same vulnerability, checked by hand:** the other case's sink (SecBench.js's, or a location of VulcaN's review)
  is inside the vulnerable function, and the advisories, as OSV (osv.dev) and Snyk give them, are of the same
  vulnerability: aliases of one another, citing the same fixing commit or report, or describing the same flaw,
  fixed in the same version. 10 of the 17 are.

| project | vulnerable commit | the same SecBench.js or VulcaN case | why it's the same vulnerability |
| --- | --- | --- | --- |
| christian-bromann/rgb2hex | `e4e0c7c38f` | vulcan/647_GHSA-65p8-3hm4-h9h8 | CVE-2018-25061 (GHSA-7599-fqgm-v84p) and GHSA-65p8-3hm4-h9h8 are both ReDoS on the color value, fixed in 0.1.6; GHSA-7599-fqgm-v84p cites this commit's fix |
| firebase/superstatic | `6628c8b63b` | vulcan/652_GHSA-wm77-q74p-5763 | GHSA-wm77-q74p-5763 cites this commit's fix, `e396ff62f5` (JsVul has npm:superstatic:20180516) |
| hughsk/flat | `e8fb281aa6` | secbench/flat_5.0.0 | SecBench.js's SNYK-JS-FLAT-596927 is CVE-2020-36632 (Snyk); its CVE-2021-25927 and GHSA-33rv-m2gp-mm2r are safe-flat's |
| mongoosejs/mquery | `2268a48083` | secbench/mquery_3.2.1 | GHSA-45q2-34rf-mr94 is CVE-2020-35149 (OSV), and SecBench.js's PoC pollutes through `__proto__`, which this commit's fix stops |
| peterbraden/node-opencv | `cfc96ba0af` | vulcan/789_GHSA-f698-m2v9-5fh3 | GHSA-f698-m2v9-5fh3 cites this commit's fix, `81a4b86201` (JsVul has CVE-2019-10061, GHSA-mc7w-4cjf-c973) |
| pkrumins/node-tree-kill | `3b5b8feeb3` | vulcan/1432_GHSA-884p-74jh-xrg2 | GHSA-884p-74jh-xrg2 (CVE-2019-15599) and CVE-2019-15598 (GHSA-j7fq-p9q7-5wfv) cite the same HackerOne report, 701183 |
| segmentio/is-url | `1498b0da8e` | secbench/is-url_1.2.2 | SecBench.js's npm:is-url:20180319 is CVE-2018-25079 (Snyk) |
| tikonen/blog | `08ab167d21` | vulcan/968 | VulcaN's npm advisory 968 (path traversal, no other id) has its location in the request handler that this commit's fix, `d85f8cf063` ("Dont return paths outside webroot"), adds the path checks to; JsVul's CVE-2018-16478 is VulcaN's `744_GHSA-vwr2-wj63-86gr`, of 0.3.0, after this fix, whose file differs |
| vercel/serve | `2fece040fb` | vulcan/594_GHSA-wm7q-rxch-43mx | CVE-2018-3718 (GHSA-5rc4-8qqh-vq7f) and GHSA-wm7q-rxch-43mx are both ignored files served when their name is URL-encoded, fixed in 6.5.2 |
| youngerheart/nodeserver | `56b51bd4bd` | secbench/web-node-server_0.1.0 | CVE-2020-36651 (GHSA-3fwq-qv5v-2wxf) and SecBench.js's npm:web-node-server:20180306 are both path traversal in web-node-server, fixed in 0.0.11 |

The 10 have 10 vulnerable functions and 5 fixed versions. The other 7 stay, as another vulnerability in the same
file:

| project | vulnerable commit | its advisory | the SecBench.js or VulcaN case's |
| --- | --- | --- | --- |
| codecov/codecov-node | `bac0787351` | CVE-2020-7597 | secbench/codecov_3.6.4: CVE-2020-15123, at the same `execSync(gcov)` |
| js-data/js-data | `0e2b07f8db` | CVE-2020-28442 | secbench/js-data_3.0.9: CVE-2021-23574, its sink outside the function |
| lodash/lodash | `67389a8c78` | CVE-2018-16487 | secbench/lodash_4.17.10: CVE-2019-10744 |
| markedjs/marked | `900e50e22a` | CVE-2017-17461 | vulcan/531_GHSA-x5pg-88wf-qq4p: CVE-2017-16114 |
| prismjs/prism | `de79636a8a` | CVE-2021-32723 | vulcan/GHSA-h4hr-7fg3-h35w: CVE-2021-23341 |
| richardgirges/express-fileupload | `e9848fc1b5` | CVE-2020-7699, prototype pollution | vulcan/1216_GHSA-q3w9-g74q-vp5f: a denial of service, although its review's location is the same `parseNested` flow |
| websockets/ws | `f7cfc51a9f` | GHSA-5v72-xg48-5rpm | vulcan/120_GHSA-6663-c963-2gqg and vulcan/67_GHSA-2mhh-w6q8-5hxw: CVE-2016-10542 and CVE-2016-10518, their sinks in other files |
