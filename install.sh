#!/usr/bin/env bash
# install.sh - restore the cases of this repository after a checkout.
#
# Usage: ./install.sh [-j N] [--fixed] [--no-deps] [--no-extras] [case-dir ...]
#
#   case-dir     cases/<name>@<ver> (path, or only the name; a package/ folder path also works).
#                Default: every case under cases/ next to this script.
#   -j N         cases in parallel for steps 2 and 3 (default 4)
#   --fixed      also build cases/<c>/fixed/: a copy of package/ (without node_modules and .git, but with the
#                node_modules/<name> folders of "siblings" in install.json) with fixed.diff applied by
#                `git apply -p1`, but for its pnpm-lock.yaml files (56 JsVul cases' fixed.diff don't apply to their
#                lock files, which were imported again after the diffs were made). Needs the extras of package/ (step 1).
#   --no-deps    skip step 2
#   --no-extras  skip step 1
#
# Steps:
#   1. extras (for all requested cases, before anything runs in parallel): cases/<c>/extra.tgz (tracked with Git LFS)
#      holds the extra files of package/ of a case (binaries, media, large data files, .gitattributes files);
#      `tar xzf extra.tgz` inside the case dir restores them. A case without extras has no archive. After a clone run
#      `git lfs pull` first: an archive that is still an LFS pointer (a small file that starts with
#      `version https://git-lfs.github.com/spec`) stops this step with that advice.
#   2. dependencies, per case (-j cases at once): in every dir of install.json run
#        pnpm install --prod --ignore-scripts --ignore-pnpmfile [--frozen-lockfile] <flags of install.json>
#      Lifecycle scripts never run. --frozen-lockfile is used when the case has a pnpm-lock.yaml; a case without one
#      prints a note, installs without a lock file and keeps the pnpm-lock.yaml that pnpm writes.
#      A dir of install.json with "omit": [names] has those dependencies in its node_modules/<name> as tracked
#      folders (the packages of the same repository, see SCHEMA.md): pnpm runs on a package.json without them, and
#      the folders stay where they are.
#      install.json names the pnpm version that made the node_modules; corepack runs that version (npx when there is
#      no corepack, as in Node.js 25 and later). A dir without a recorded version uses the pnpm of the PATH (npx's
#      pnpm@9.15.9 when there is none); when the package.json asks for another pnpm version (engines.pnpm,
#      packageManager) and the install fails for that reason, it is repeated with the version the package.json names.
#      The pnpm output goes to cases/<c>/.install/pnpm-<dir>.log.
#   3. fixed (--fixed), per case: see above.
# Every step is skipped when it is finished (markers in cases/<c>/.install/; a dir whose node_modules exists
# without a marker counts as installed), so a second run changes nothing. A failed case prints the reason and
# the exit code is 1; the other cases go on. Files that .gitignore rules exclude are not in the repository and are
# not restored. Needs bash, tar, git (--fixed) and pnpm or npx (dependencies); no Python.

set -u -o pipefail

SELF=$(readlink -f "${BASH_SOURCE[0]}")
ROOT=$(dirname "$SELF")
CASES_DIR=$ROOT/cases

usage() { sed -n '2,/^$/p' "$SELF" | sed 's/^# \{0,1\}//' | sed '$d'; }

JOBS=4 FIXED=0 DEPS=1 EXTRAS=1 ONE=0
targets=()
while (($#)); do
  case $1 in
    -j) shift; JOBS=${1:-}; [[ $JOBS =~ ^[1-9][0-9]*$ ]] || { echo "install.sh: -j needs a number" >&2; exit 2; } ;;
    -j[0-9]*) JOBS=${1#-j} ;;
    --fixed) FIXED=1 ;;
    --no-deps) DEPS=0 ;;
    --no-extras) EXTRAS=0 ;;
    --one) ONE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "install.sh: unknown option $1" >&2; usage >&2; exit 2 ;;
    *) targets+=("$1") ;;
  esac
  shift
done

resolve_case() {
  local a=$1 p
  if [[ -d $a ]]; then p=$(readlink -f "$a")
  elif [[ -d $CASES_DIR/$a ]]; then p=$(readlink -f "$CASES_DIR/$a")
  else echo "install.sh: no such case: $a" >&2; return 1; fi
  [[ $(basename "$p") == package ]] && p=$(dirname "$p")
  [[ $(dirname "$p") == "$(readlink -f "$CASES_DIR")" ]] || { echo "install.sh: $a is not a case dir below $CASES_DIR" >&2; return 1; }
  printf '%s\n' "$p"
}

say() { printf '%s: %s\n' "$NAME" "$*"; }

PNPM=(pnpm)
pnpm --version > /dev/null 2>&1 || PNPM=(npx --yes pnpm@9.15.9)  # npx's pnpm when the PATH has no pnpm that runs

extract_extras() {  # case dirs as arguments; the archive of each case that is not restored yet
  local c a id n=0
  for c in "$@"; do
    a=$c/extra.tgz
    [[ -f $a ]] || continue
    if (($(wc -c < "$a") < 1024)) && head -c 40 "$a" | grep -q '^version https://git-lfs.github.com/spec'; then
      echo "install.sh: cases/$(basename "$c")/extra.tgz is a Git LFS pointer, not the archive. Run 'git lfs pull', then start again." >&2
      return 2
    fi
    id=$(cksum < "$a" | cut -d' ' -f1,2)
    [[ -f $c/.install/extras && $(<"$c/.install/extras") == "$id" ]] && continue
    if ! tar -xzf "$a" -C "$c" --no-same-owner 2> "$c/.extract.err"; then
      echo "install.sh: FAILED extracting cases/$(basename "$c")/extra.tgz: $(tail -n 3 "$c/.extract.err" | tr '\n' ' ')" >&2
      rm -f "$c/.extract.err"; return 1
    fi
    rm -f "$c/.extract.err"
    mkdir -p "$c/.install"; printf '%s\n' "$id" > "$c/.install/extras"
    n=$((n + 1))
  done
  if ((n == 0)); then echo "extras already restored"; else echo "extras restored for $n cases"; fi
}

pnpm_args() {  # $1 = flags string, $2 = 1 for frozen, $3 = pinned (pnpm of the package.json) or default
  PNPM_ARGS=(install --prod --ignore-scripts --ignore-pnpmfile --reporter=append-only
             --registry https://registry.npmjs.org/ --config.blockExoticSubdeps=false)
  [[ $3 == pinned ]] || PNPM_ARGS+=(--config.pmOnFail=ignore)
  [[ $1 == *"--filter ."* ]] || PNPM_ARGS+=(--ignore-workspace)  # a dir that is no workspace member
  local fl=() f
  read -ra fl <<< "$1"
  for f in "${fl[@]+"${fl[@]}"}"; do PNPM_ARGS+=("$f"); done
  [[ $2 == 1 ]] && PNPM_ARGS+=(--frozen-lockfile)
  return 0
}

run_pnpm() {  # $1 = cwd, $2 = log, $3 = pinned or default; PNPM_VERSION = the pnpm version of install.json
  local spec=0 manage=false cmd=("${PNPM[@]}")
  [[ $3 == pinned ]] && { spec=1; manage=true; }
  if [[ -n $PNPM_VERSION && $3 != pinned ]]; then  # the pnpm that made node_modules
    if command -v corepack > /dev/null; then cmd=(corepack "pnpm@$PNPM_VERSION"); else cmd=(npx --yes "pnpm@$PNPM_VERSION"); fi
  fi
  (cd "$1" && env COREPACK_ENABLE_PROJECT_SPEC=$spec COREPACK_ENABLE_AUTO_PIN=0 COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
      npm_config_manage_package_manager_versions=$manage pnpm_config_manage_package_manager_versions=$manage \
      timeout 1200 "${cmd[@]}" "${PNPM_ARGS[@]}") > "$2" 2>&1
}

omit_prepare() {  # $1 = case, $2 = cwd, $3 = key, rest = names: strip them from package.json, set their folders aside
  local c=$1 cwd=$2 key=$3 keep n
  shift 3
  keep=$c/.install/keep.$key
  rm -rf "$keep"; mkdir -p "$keep/nm"
  cp -p "$cwd/package.json" "$keep/package.json.orig"
  for n in "$@"; do
    if [[ -e $cwd/node_modules/$n ]]; then mkdir -p "$keep/nm/$(dirname "$n")"; mv "$cwd/node_modules/$n" "$keep/nm/$n"; fi
  done
  node -e 'const fs=require("fs");const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,"utf8"));
    for(const k of ["dependencies","optionalDependencies","devDependencies","peerDependencies"]){if(j[k])for(const n of process.argv.slice(2))delete j[k][n];}
    fs.writeFileSync(f,JSON.stringify(j,null,2)+"\n");' "$cwd/package.json" "$@"
}

omit_restore() {  # same arguments: package.json and the folders back; what pnpm put at their places is removed
  local c=$1 cwd=$2 key=$3 keep n
  shift 3
  keep=$c/.install/keep.$key
  [[ -f $keep/package.json.orig ]] || return 0
  cp -p "$keep/package.json.orig" "$cwd/package.json"
  for n in "$@"; do
    if [[ -e $keep/nm/$n ]]; then
      rm -rf "${cwd:?}/node_modules/$n"; mkdir -p "$cwd/node_modules/$(dirname "$n")"; mv "$keep/nm/$n" "$cwd/node_modules/$n"
    fi
  done
  rm -rf "$keep"
}

install_dir() {
  local c=$1 dir=$2 lock=$3 flags=$4 PNPM_VERSION=$5 omit=${6:-} cwd key log frozen=0 how="" names=()
  cwd=$c/$dir
  key=$(printf '%s' "$dir" | tr -c 'A-Za-z0-9._-' '_')
  log=$c/.install/pnpm-$key.log
  if [[ -f $c/.install/deps.$key.ok ]]; then say "$dir: dependencies already installed"; return 0; fi
  if [[ ! -f $c/.install/deps.$key.started && -d $cwd/node_modules && -n $(ls -A "$cwd/node_modules") ]]; then
    # the tracked folders of "omit" fill node_modules without any install: pnpm's .modules.yaml tells
    if [[ -z $omit || -f $cwd/node_modules/.modules.yaml ]]; then say "$dir: node_modules present"; return 0; fi
  fi
  if [[ ! -d $cwd ]]; then say "FAILED $dir: directory missing (extras not restored?)"; return 1; fi
  if [[ -n $lock && -f $c/$lock ]]; then frozen=1
  else say "NOTE $dir: no pnpm-lock.yaml; installing without a lock file (newest versions the ranges allow); the pnpm-lock.yaml that pnpm writes stays"; fi
  : > "$c/.install/deps.$key.started"
  local rc=0
  if [[ -n $omit ]]; then
    omit=${omit//\"/}; IFS=, read -ra names <<< "$omit"
    omit_prepare "$c" "$cwd" "$key" "${names[@]}"
  fi
  pnpm_args "$flags" "$frozen" default
  run_pnpm "$cwd" "$log" default || rc=1
  if ((rc)) && [[ $flags == *"--filter ."* ]] && grep -q "No projects matched" "$log"; then
    flags=${flags/--filter ./}  # the dir is no project of its workspace: --ignore-workspace instead
    how=" (--ignore-workspace)"
    pnpm_args "$flags" "$frozen" default
    rc=0; run_pnpm "$cwd" "$log" default || rc=1
  fi
  if ((rc)) && grep -qE "ERR_PNPM_UNSUPPORTED_ENGINE|configured to use .* of pnpm" "$log"; then
    how="$how (pnpm version of the package.json)"  # the package asks for another pnpm: corepack runs that one
    pnpm_args "$flags" "$frozen" pinned
    rc=0; run_pnpm "$cwd" "$log" pinned || rc=1
  fi
  [[ -n $omit ]] && omit_restore "$c" "$cwd" "$key" "${names[@]}"
  if ((rc)); then
    say "FAILED $dir: pnpm install failed; last lines of $log: $(tail -n 4 "$log" | tr '\n' ' ')"
    return 1
  fi
  touch "$c/.install/deps.$key.ok"; rm -f "$c/.install/deps.$key.started"
  say "$dir: dependencies installed$([[ $frozen == 1 ]] && echo ' (frozen lockfile)')$how"
}

step_deps() {
  local c=$1 line dir lock flags pnpm rc=0 n=0
  [[ -f $c/install.json ]] || { say "no install.json"; return 0; }
  while IFS= read -r line; do
    [[ $line =~ \"dir\":\ \"([^\"]*)\" ]] || continue
    dir=${BASH_REMATCH[1]}
    lock="" flags="" pnpm="" omit=""
    [[ $line =~ \"lock\":\ \"([^\"]*)\" ]] && lock=${BASH_REMATCH[1]}
    [[ $line =~ \"flags\":\ \"([^\"]*)\" ]] && flags=${BASH_REMATCH[1]}
    [[ $line =~ \"pnpm\":\ \"([^\"]*)\" ]] && pnpm=${BASH_REMATCH[1]}
    [[ $line =~ \"omit\":\ \[([^]]*)\] ]] && omit=${BASH_REMATCH[1]// /}
    n=$((n + 1))
    install_dir "$c" "$dir" "$lock" "$flags" "$pnpm" "$omit" || rc=1
  done < "$c/install.json"
  ((n)) || say "no dependencies to install"
  return $rc
}

step_fixed() {
  local c=$1 tmp
  if [[ -d $c/fixed ]]; then say "fixed/ exists"; return 0; fi
  if [[ ! -f $c/fixed.diff ]] && ! grep -q '"fixed": "same"' "$c/install.json" 2> /dev/null; then return 0; fi
  tmp=$c/.fixed.tmp.$$
  rm -rf "$tmp"; mkdir "$tmp"
  if ! { (cd "$c/package" && tar -cf - --exclude=node_modules --exclude=.git --exclude=pnpm-install.log .) |
         tar -xf - -C "$tmp"; }; then
    rm -rf "$tmp"; say "FAILED fixed: copy of package/ failed"; return 1
  fi
  local names n  # the tracked packages of the same repository ("siblings" of install.json) belong to fixed/ too
  names=$(sed -n 's/.*"siblings": \[\([^]]*\)\].*/\1/p' "$c/install.json" 2> /dev/null | tr -d '" ' | tr ',' '\n')
  for n in $names; do
    if [[ -d $c/package/node_modules/$n ]]; then
      mkdir -p "$tmp/node_modules/$(dirname "$n")"; cp -a "$c/package/node_modules/$n" "$tmp/node_modules/$n"
    fi
  done
  if [[ -f $c/fixed.diff ]]; then
    local err
    if ! err=$(cd "$tmp" && GIT_CEILING_DIRECTORIES=$c GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
        git -c core.autocrlf=false -c core.safecrlf=false apply -p1 --whitespace=nowarn --exclude='*pnpm-lock.yaml' "$c/fixed.diff" 2>&1); then
      rm -rf "$tmp"; say "FAILED fixed: git apply: $(printf '%s' "$err" | tail -n 3 | tr '\n' ' ')"; return 1
    fi
  fi
  mv "$tmp" "$c/fixed"
  say "fixed/ restored"
}

process_case() {
  local c=$1 rc=0
  NAME=$(basename "$c")
  if [[ ! -d $c ]]; then echo "$NAME: FAILED not a directory" >&2; return 1; fi
  mkdir -p "$c/.install"
  if ((DEPS)); then step_deps "$c" || rc=1; fi
  if ((FIXED)); then step_fixed "$c" || rc=1; fi
  return $rc
}

# ---- worker mode (one case, called by the parallel driver below)
if ((ONE)); then
  process_case "${targets[0]}"; rc=$?
  ((rc)) && [[ -n ${INSTALL_FAILLOG:-} ]] && basename "${targets[0]}" >> "$INSTALL_FAILLOG"
  exit $rc
fi

# ---- driver
if ((DEPS)) && [[ ${PNPM[0]} == npx ]] && ! command -v npx > /dev/null; then echo "install.sh: neither pnpm nor npx found (use --no-deps to skip)" >&2; exit 2; fi
if ((FIXED)) && ! command -v git > /dev/null; then echo "install.sh: git not found (needed by --fixed)" >&2; exit 2; fi
command -v tar > /dev/null || { echo "install.sh: tar not found" >&2; exit 2; }

list=()
if ((${#targets[@]})); then
  for t in "${targets[@]}"; do p=$(resolve_case "$t") || exit 2; list+=("$p"); done
else
  [[ -d $CASES_DIR ]] || { echo "install.sh: $CASES_DIR not found" >&2; exit 2; }
  for d in "$CASES_DIR"/*/; do
    d=${d%/}
    [[ -f $d/case.json || -d $d/package ]] && list+=("$d")
  done
fi
((${#list[@]})) || { echo "install.sh: no cases" >&2; exit 2; }

if ((EXTRAS)); then
  extract_extras "${list[@]}"; rc=$?
  if ((rc)); then exit "$rc"; fi
fi

FAILLOG=$(mktemp) || exit 2
trap 'rm -f "$FAILLOG"' EXIT
export INSTALL_FAILLOG=$FAILLOG
flags=()
((FIXED)) && flags+=(--fixed)
((DEPS)) || flags+=(--no-deps)
printf '%s\0' "${list[@]}" | xargs -0 -n1 -P "$JOBS" "$SELF" --one "${flags[@]}" || true

if [[ -s $FAILLOG ]]; then
  echo "install.sh: $(sort -u "$FAILLOG" | wc -l) of ${#list[@]} cases failed:" >&2
  sort -u "$FAILLOG" | sed 's/^/  /' >&2
  exit 1
fi
echo "install.sh: ${#list[@]} cases done"
