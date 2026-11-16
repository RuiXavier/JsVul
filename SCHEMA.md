# Unified benchmark format

All benchmarks (SecBench.js, VulcaN, JsVul) are stored as cases under `cases/`. One directory holds one package
version (npm) or one repository commit (GitHub), with every vulnerability known for it.

```
cases/<name>@<version>/        npm package (SecBench.js, VulcaN):  crud-file-server@0.8.0, a__b@1.0.0 for @a/b
cases/<repo>@<sha7>/           GitHub commit (JsVul):               lodash@5a3ff73
  case.json
  package/                     the code, with its production dependencies installed; for a JsVul case in a monorepo the
                               folder that holds the sinks (`subdir`), with the packages of the same repository that it
                               depends on in package/node_modules/<name> (`siblings`)
  poc/                         the proof of concept files (only when a case has one)
  patch/                       the patch files (only when a case has one)
  fixed/                       JsVul only: the fixing commit's code (of the same folder as package/)
  fixed.diff                   `git diff` from package/ to fixed/ (with the extras of package/ in place, and the
                               node_modules/<name> folders of `siblings`)
  install.json                 the dependency install dirs of package/ with their lock file, pnpm flags and omitted dependencies
  extra.tgz                    the extras of package/ (non-code files), tracked with Git LFS (see .gitattributes); only
                               when the case has extras
```

`cases/<case>/extra.tgz` is a tar.gz archive of the non-code files of `package/` of that case (media, binaries, large
data, every `.gitattributes` file, and every file of a binary suffix: a suffix of which more files hold a NUL byte than
not), as members `package/<path>`; `tar xzf extra.tgz` inside the case directory restores them. The archive is
reproducible (sorted members, mtime 0, no owner, gzip mtime 0), so equal content gives equal bytes and repacking an
unchanged case leaves its archive (and its Git LFS object) as it is. In the repository `package/` holds code, small text files and lock
files; files that a `.gitignore` rule excludes are not part of the repository. `pack_case.py <case-dir>` (or `--all`)
collects the extras of a case into its archive, writes `fixed.diff` and `install.json`, and removes the extras, `fixed/`
and the nested `.git` folders from the case. `install.sh [-j N] [--fixed] [case-dir ...]` restores them. The extras block of the repository `.gitignore` (written by `pack_case.py` from the members of the archives: `*.suffix` for the binary suffixes, a folder or file path for the rest) and the rule `/cases/*/fixed/` keep the restored extras and `fixed/` trees out of `git status`. A JsVul case of a monorepo keeps the folder of its sinks as `package/` and the packages of the same repository that
this folder depends on (`dependencies` and `optionalDependencies`, followed through their own dependencies on such
packages) in `package/node_modules/<name>`: their code and small text files, tracked in Git with `git add -f` although
`node_modules/` is ignored. `install.json` lists the names of these packages as `siblings`, and the dependencies among them that
`package.json` declares (including every `workspace:` reference) as `omit`: `install.sh` runs pnpm on a
`package.json` without them (a `workspace:` reference has no workspace to resolve in), leaves their folders in place
and restores the `package.json`. After a
clone run `git lfs pull` (it fetches the archives), then `./install.sh`: it extracts the archive of each requested case, installs the
dependencies listed in `install.json` with pnpm (`node_modules` is not in the repository, apart from the `siblings` folders; every install dir has a `pnpm-lock.yaml`
where one could be made), and with `--fixed` rebuilds `fixed/` from `package/` and `fixed.diff`.

`buildscript/unified_case.py` writes case directories and case.json; every converter in `buildscript/converters/` uses it.
`check_case.py` checks case.json files against this schema: every field of the tables below is required (`origin`
and `role` too), except the fields that a table marks as present only in some cases. `python3 check_case.py`
checks all cases; after `python3 check_case.py --install-hook` in a clone, git runs it on the staged case.json files
before each commit and each merge commit.
The folder `buildscript/` holds the one-off scripts that made the cases; Git ignores it.

Scope: the benchmark holds the injection classes `code-injection`, `command-injection` and `path-traversal`, and
the class `stored-command-injection` that the review assigns (below).
`buildscript/converters/filter_scope.py` keeps a benchmark's output to them.

## case.json

```json
{
  "name": "crud-file-server",
  "version": "0.8.0",
  "repo": null,
  "sha": null,
  "from": ["vulcan"],
  "origin": "npm",
  "role": "library",
  "entry": ["package"],
  "capabilities": null,
  "vulnerabilities": [
    {
      "id": "GHSA-vfp9-gwrh-wq9g",
      "from": "vulcan",
      "cve": ["CVE-2018-3733"],
      "ghsa": ["GHSA-vfp9-gwrh-wq9g"],
      "snyk": [],
      "cwe": ["CWE-22"],
      "class": "path-traversal",
      "sinks": [
        {"file": "package/crud-file-server.js", "startline": 187, "startcol": 19,
         "endline": 187, "endcol": 53, "range": false,
         "code": "fs.createWriteStream(relativePath)"}
      ],
      "sources": [
        {"file": "package/crud-file-server.js", "startline": 36, "startcol": null,
         "endline": 36, "endcol": null, "range": false}
      ],
      "poc": "https://hackerone.com/reports/310690",
      "fix": {
        "version": null,
        "commit": "https://github.com/omphalos/crud-file-server/commit/4fc3b404f718abb789f4ce4272c39c7a138c7a82",
        "patch": null,
        "locations": []
      }
    }
  ]
}
```

(The example shows one of the eight sinks of `cases/crud-file-server@0.8.0`.)

### Case fields

| field | value |
|---|---|
| `name` | npm package name with `@scope/name` written `scope__name`; for a GitHub case the repository name (the part after `owner/`) |
| `version` | the package version; `null` for a GitHub case |
| `repo`, `sha` | `owner/repo` and the full commit sha of a GitHub case; `null` for an npm case |
| `subdir`, `siblings` | present when `package/` is a folder of a larger repository: `subdir` is the folder's path in the repository (`packages/nuxt`), `siblings` maps each package folder in `package/node_modules/` to its path in the repository (`{"@nuxt/kit": "packages/kit"}`) |
| `from` | the benchmarks that hold this case: `secbench`, `vulcan`, `jsvul` |
| `origin` | where the code of `package/` comes from: `npm` (the package that npm publishes as name@version, usually built JavaScript) or `repository` (the files of the source repository, at `sha` when the case gives one; often TypeScript sources without a build) |
| `role` | what the code is: `library` (other code loads it with `require` or `import` and calls its API), `application` (it runs by itself: a server, a command-line program, an Electron application), `action` (a GitHub Action: the runner starts it for a workflow step, and the attacker's data enters through the step's inputs, the environment and the event payload), `mcp` (an MCP server that an MCP client starts and whose tools the client calls) or `extension` (an editor extension: the editor loads it and calls `activate`, and the attacker's data enters through the editor API, such as workspace files, settings and webview messages; the editor gives the `vscode` module, which `node_modules` does not hold) |
| `entry` | the paths (relative to the case directory) that an analysis of `package/` starts from: a folder starts from the entry files that its package.json names (`main`, `exports`, `bin`), a file from itself (with `package/` as the base directory). `["package"]` for every npm case and for a JsVul case whose `package/` is the package folder; another JsVul case names the folder of the nearest package.json above its sink files, or the sink file when none lies above it; a case whose package.json names entry files that the repository does not hold (an unbuilt `dist/`) names the source files instead. The fixed side starts from the same paths under `fixed/` |
| `capabilities` | `null` until the package is classified; later `{"Cmd","Eval","FSRead","FSWrite","Net","DB"}` each `ALL`, `SCOPED` or `NONE` |
| `vulnerabilities` | one entry per advisory or vulnerable commit |

`origin` is `repository` for every GitHub case. An npm case is `npm` when its files are the files of the registry
package name@version (`npm pack <name>@<version> --dry-run`); 7 npm cases hold the repository files instead and are
`repository` (devcert@1.1.1, git-tags-remote@1.0.3, gitlog@4.0.3, kill-process-on-port@1.0.2, prisma__sdk@2.19.0,
rollup-plugin-serve@1.0.1, takeapeek@0.2.2). The 7 versions that the registry no longer has stay `npm`.

`role` comes from the code, by the first rule that applies: a VS Code extension (`engines.vscode`) is `extension`;
a GitHub Action (`action.yml`) is `action`; an Electron application, a command-line program (`bin` and no `main`, `exports` or `index.js`),
a main file that starts a server and exports nothing, and a private package of a repository are `application`; a
package that creates a server of `@modelcontextprotocol/sdk` is `mcp`; an npm package with an API is `library`; a
GitHub case keeps the role of its earlier `type` (`library` when npm has a package of the same name and the
package.json at the commit has `main` or `exports`). `buildscript/set_origin_role.py` applies these rules, with
three cases set by hand (agent@9d1697d `application`, ng-packagr@6484138 `library`, mcp-remote@3ad0fc0 `mcp`).

An analysis that treats `package/` as a published library (jelly `--library`) fits `origin: npm` with
`role: library`.

### Vulnerability fields

| field | value |
|---|---|
| `id` | the first of GHSA id, CVE id, Snyk id, npm advisory id, the benchmark's own id |
| `from` | `secbench`, `vulcan` or `jsvul` |
| `cve`, `ghsa`, `snyk` | lists of advisory ids, empty when there is none |
| `cwe` | list of CWE ids of the vulnerability |
| `class` | `code-injection`, `command-injection`, `path-traversal`, `prototype-pollution` or `redos`, from the CWE classes below, or `stored-command-injection`, which the review assigns; `null` when the CWE is in none of them |
| `originalClass` | present when the review corrected the class: the class that the CWE of the source benchmark gives. `class` then holds the class of the operation at the sinks (an `eval` sink is `code-injection`, a `child_process` sink is `command-injection`); `cwe` keeps the advisory's CWE ids (DIFF_WITH_ORIGINAL.md section 5 lists the cases) |
| `sinks` | at least one location; every sink is needed: a tool finds the vulnerability when it reports each of its sinks. A sink is the call of a native function that does the dangerous operation (`fs.*`, `child_process.*`, `eval`, `Function`, `vm.*`, `require` or `import()` of a computed name) and that the attacker-controlled value reaches; for path traversal, a call that only checks the path (`stat`, `lstat`, `exists`, `access`, `realpath`) is a sink only when the flow reaches no other native call; a sink in a dependency has the logical path `package/node_modules/<name>/...` (below) |
| `originalSink` | present when the sinks were re-labelled: the sinks the vulnerability had before, as the source benchmark gives them. The labelled place (a check, a wrapper, the call into a package, a whole function) was followed down through the package and its dependencies to the native calls that `sinks` now holds. The SecBench.js and VulcaN forks moved 23 sinks of wrapper packages that way (their upstream labels are the `originalSink`); 24 JsVul vulnerabilities were re-labelled on 2026-11-12 and the JsVul function ranges after them (DIFF_WITH_ORIGINAL.md lists the cases). Absent when the benchmark's sinks stand |
| `sources` | locations, an empty list when the benchmark has none (VulcaN gives sources; SecBench.js and JsVul give none, apart from the two that the SecBench.js fork annotates, kmc and mobile-icon-resizer) |
| `sourceKinds` | a list, present when the attacker's data enters the package by another way than the arguments of its API, its command line or a network request to it; one value for each kind of source that the vulnerability has: `environment` (an environment variable), `file` (content that is already in the file system, such as a symbolic link placed before the package runs) or `process-output` (the output of a program that the package runs itself: the return value or stdout of a `child_process` call, such as the SSID in the output of `nmcli` or `netsh`; `sources` then holds these calls) |
| `poc` | `null`, or one string: a path under the case directory (`poc/...`) or a URL |
| `fix.version`, `fix.commit` | the fixed version and the fixing commit (URL or sha), `null` when unknown |
| `fix.patch` | `null`, or a path under the case directory (`patch/...`) |
| `fix.locations` | the fixed counterparts of the sinks, in the same shape as `sinks`; empty when there is none. A JsVul case records the fix when the fixing commit changes the package folder or a package of `siblings`; the changes elsewhere in the repository (other packages, tests, docs) are outside `fixed/` |

### PoC

A PoC file is a standalone Node.js script without a test framework: `node poc/<id>.js` runs it, it loads the
vulnerable package with `require('../package')` (and its dependencies from `../package/node_modules`), and it ends
by itself with exit code 0 when the vulnerability is triggered, 1 when it is not, and prints one line that says
what happened. A URL PoC is the URL as the string.

### Location

```
{"file": "...", "startline": 1, "startcol": 1, "endline": 1, "endcol": 30, "range": false, "code": "..."}
```

- `file` is relative to the case directory and starts with `package/`, for example
  `package/crud-file-server.js` or `package/node_modules/shelljs/src/exec.js` (a sink in a dependency).
- A file in a dependency has its logical path `package/node_modules/<name>/<path in the package>` (scoped:
  `package/node_modules/@scope/name/...`), the path by which Node.js finds the package from `package/`, never the
  folder of the package manager's store (`node_modules/.pnpm/<name>@<version>/...`). A tool resolves `<name>` in the
  installed tree: the link `package/node_modules/<name>` of a direct dependency, or the one installed version of
  `<name>` in the store. When two versions are installed, the path nests the way Node.js resolves it from the package
  that calls it (`package/node_modules/<a>/node_modules/<name>/...`).
- Lines and columns are 1-based. A column counts the characters of the line decoded from UTF-8 (all JSON is UTF-8;
  in the three package files that are not, `infraserver@0.0.1` `Infra.data.js` and `desafio.js` of `desafio@1.1.0` and
  `dasafio@1.2.0`, a byte that is no UTF-8 counts as one character); no stored column follows a non-ASCII character,
  so characters and UTF-16 units agree.
  A column the benchmark does not hold is `null`.
- `range` is `false` for one code node (a source or a sink call) and `true` for a region (a function or a block)
  that holds the sink somewhere inside.
- A sink node (`range: false`) is the call expression of the sink, from the first character of the callee (or of
  `new`) to the closing parenthesis: `endcol` is one past its last character, and `code` is the source text of the
  span. `buildscript/normalize_sinks.py` derives the span from the start the benchmark gives (SecBench.js gives a
  point of the call, VulcaN a line) by parsing the file with @babel/parser; the sinks it cannot decide keep the
  benchmark's location with `code: null` (a line that holds two sink calls, a minified file, a file that is no
  JavaScript). A range (`range: true`) has `code: null`.
- A source and an `originalSink` keep the location the benchmark gives; `endline` and `endcol` are `null` when it
  gives none, and they have no `code`.
- A function range of JsVul is a region in the original file of the repository, not in the file as JsVul formatted it.

### CWE classes

| class | CWEs |
|---|---|
| code injection | CWE-94, CWE-95, CWE-96, CWE-97, CWE-1336 |
| command injection | CWE-77, CWE-78, CWE-88, CWE-624, CWE-917 |
| path traversal | CWE-22 to CWE-40, CWE-59, CWE-61, CWE-62, CWE-64, CWE-65, CWE-73, CWE-114, CWE-1386 |
| prototype pollution | CWE-471, CWE-915, CWE-1321 |
| ReDoS | CWE-400, CWE-730, CWE-1333 |
| stored command injection | assigned by the review, with the benchmark's class in `originalClass`: the attacker's data is first stored (a configuration file, an environment file such as `.env` or `GITHUB_ENV`, a workflow command, a saved tool configuration) and a later step runs a command from the stored data. The sinks are the place that stores the data, or the process start that reads the stored configuration |
