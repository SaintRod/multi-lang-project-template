#!/bin/bash
# Characterization tests for create-project.sh.
# Plain bash on purpose: no test framework, no dependencies.
# Run: bash tests/create-project_test.sh
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
create="$here/../create-project.sh"

checks=0
failures=0

ok() { checks=$((checks + 1)); printf 'ok   %s\n' "$1"; }
no() { checks=$((checks + 1)); failures=$((failures + 1)); printf 'FAIL %s\n' "$1"; }

assert_dir() { [[ -d "$2" ]] && ok "$1" || no "$1 (missing dir: $2)"; }
assert_no_dir() { [[ ! -e "$2" ]] && ok "$1" || no "$1 (unexpected path: $2)"; }
assert_file() { [[ -f "$2" ]] && ok "$1" || no "$1 (missing file: $2)"; }
assert_line() { grep -qxF -- "$2" "$3" && ok "$1" || no "$1 (missing line '$2' in $3)"; }
assert_no_line() { grep -qxF -- "$2" "$3" && no "$1 (unexpected line '$2' in $3)" || ok "$1"; }
assert_eq() { [[ "$2" == "$3" ]] && ok "$1" || no "$1 (expected '$3', got '$2')"; }
assert_contains() { [[ "$3" == *"$2"* ]] && ok "$1" || no "$1 (missing '$2' in output: $3)"; }
assert_not_contains() { [[ "$3" != *"$2"* ]] && ok "$1" || no "$1 (unexpected '$2' in output: $3)"; }
assert_rc() { [[ "$last_rc" == "$2" ]] && ok "$1" || no "$1 (expected exit $2, got $last_rc)"; }

# Run create-project.sh, capturing combined output and exit status.
last_rc=0
last_out=""
run() {
    last_rc=0
    last_out=$("$create" "$@" 2>&1) || last_rc=$?
    return 0
}

# Same, with a PATH prefix so a stub can shadow a tool
run_with_path() {
    local prefix="$1"; shift
    last_rc=0
    last_out=$(PATH="$prefix:$PATH" "$create" "$@" 2>&1) || last_rc=$?
    return 0
}

# The R branch shells out to R and runs renv::init. Stub it so the R
# cases exercise the scaffold without needing an R install.
shim=$(mktemp -d)
printf '#!/bin/sh\nexit 0\n' > "$shim/R"
chmod +x "$shim/R"
PATH="$shim:$PATH"

# A stub that fails, to prove a broken R is not reported as success
rshim=$(mktemp -d)
printf '#!/bin/sh\nexit 1\n' > "$rshim/R"
chmod +x "$rshim/R"

work=$(mktemp -d)
# Stay inside the trap-cleaned dir so a CWD-relative scaffold can't escape it.
cd "$work"
trap 'rm -rf "$work" "$shim" "$rshim"' EXIT

default_dirs=(
    data data/input data/output documentation config notebooks
    src scripts research plans handoffs
)

# --- no -l: every default dir plus both test dirs -------------------------
d="$work/nolang"; mkdir -p "$d"
run -p "$d"
assert_rc "no -l exits 0" 0
for dir in "${default_dirs[@]}"; do
    assert_dir "no -l creates $dir" "$d/$dir"
done
assert_dir "no -l creates test" "$d/test"
assert_dir "no -l creates tests" "$d/tests"
assert_file "no -l creates .gitignore" "$d/.gitignore"
assert_file "no -l creates LICENSE" "$d/LICENSE"
assert_file "no -l creates README.md" "$d/README.md"
assert_line "no -l ignores .env" ".env" "$d/.gitignore"
assert_no_line "no -l has no R block" ".Renviron" "$d/.gitignore"
assert_no_line "no -l has no Python block" "__pycache__/" "$d/.gitignore"
assert_no_line "no -l has no Julia block" "*.jl.cov" "$d/.gitignore"

# --- -l r ------------------------------------------------------------------
d="$work/r"; mkdir -p "$d"
run -l r -p "$d"
assert_rc "-l r exits 0" 0
assert_dir "-l r creates tests" "$d/tests"
assert_no_dir "-l r omits test" "$d/test"
assert_file "-l r creates .Renviron" "$d/.Renviron"
assert_line "-l r ignores .Renviron" ".Renviron" "$d/.gitignore"
assert_line "-l r ignores .Rhistory" ".Rhistory" "$d/.gitignore"
assert_no_line "-l r has no Python block" "__pycache__/" "$d/.gitignore"
assert_eq "-l r gitignore is 16 lines" "$(wc -l < "$d/.gitignore")" "16"

# --- -l py / -l python -----------------------------------------------------
for lang in py python; do
    d="$work/$lang"; mkdir -p "$d"
    run -l "$lang" -p "$d"
    assert_rc "-l $lang exits 0" 0
    assert_dir "-l $lang creates tests" "$d/tests"
    assert_no_dir "-l $lang omits test" "$d/test"
    assert_line "-l $lang ignores __pycache__/" "__pycache__/" "$d/.gitignore"
    assert_line "-l $lang ignores .venv/" ".venv/" "$d/.gitignore"
    assert_no_line "-l $lang has no R block" ".Renviron" "$d/.gitignore"
    assert_no_line "-l $lang has no Julia block" "*.jl.cov" "$d/.gitignore"
    assert_eq "-l $lang gitignore is 22 lines" "$(wc -l < "$d/.gitignore")" "22"
done

# --- -l jl / -l julia ------------------------------------------------------
for lang in jl julia; do
    d="$work/$lang"; mkdir -p "$d"
    run -l "$lang" -p "$d"
    assert_rc "-l $lang exits 0" 0
    assert_dir "-l $lang creates test" "$d/test"
    assert_no_dir "-l $lang omits tests" "$d/tests"
    assert_line "-l $lang ignores *.jl.cov" "*.jl.cov" "$d/.gitignore"
    assert_no_line "-l $lang has no Python block" "__pycache__/" "$d/.gitignore"
done

# --- -l is case-insensitive ------------------------------------------------
d="$work/upper-r"; mkdir -p "$d"
run -l R -p "$d"
assert_rc "-l R exits 0" 0
assert_file "-l R creates .Renviron" "$d/.Renviron"
assert_no_dir "-l R omits test" "$d/test"

d="$work/upper-py"; mkdir -p "$d"
run -l PYTHON -p "$d"
assert_dir "-l PYTHON creates tests" "$d/tests"
assert_no_dir "-l PYTHON omits test" "$d/test"

d="$work/mixed-jl"; mkdir -p "$d"
run -l Julia -p "$d"
assert_dir "-l Julia creates test" "$d/test"
assert_no_dir "-l Julia omits tests" "$d/tests"

# --- re-runs are idempotent ------------------------------------------------
d="$work/idempotent"; mkdir -p "$d"
run -l py -p "$d"; first=$(wc -l < "$d/.gitignore")
run -l py -p "$d"; second=$(wc -l < "$d/.gitignore")
assert_eq "second run adds no gitignore lines" "$second" "$first"
assert_eq "no duplicate .env lines" "$(grep -cxF -- '.env' "$d/.gitignore")" "1"

# --- existing .gitignore content is preserved ------------------------------
d="$work/preserve"; mkdir -p "$d"
printf 'my-custom/\n.env\n' > "$d/.gitignore"
run -l py -p "$d"
assert_rc "-l py over existing .gitignore exits 0" 0
assert_line "preserves custom pattern" "my-custom/" "$d/.gitignore"
assert_eq "does not duplicate existing .env" "$(grep -cxF -- '.env' "$d/.gitignore")" "1"

# --- .gitignore without a trailing newline ---------------------------------
d="$work/nonewline"; mkdir -p "$d"
printf 'custom-line' > "$d/.gitignore"
run -l r -p "$d"
assert_line "preserves unterminated line" "custom-line" "$d/.gitignore"
assert_line "appends .env on its own line" ".env" "$d/.gitignore"
assert_no_line "does not glue onto previous line" "custom-line.env" "$d/.gitignore"

# --- unknown -l falls back to both test dirs -------------------------------
d="$work/unknown"; mkdir -p "$d"
run -l go -p "$d"
assert_rc "-l go exits 0" 0
assert_dir "-l go creates test" "$d/test"
assert_dir "-l go creates tests" "$d/tests"

# --- error paths -----------------------------------------------------------
run -l py
assert_rc "missing -p fails" 1
assert_contains "missing -p explains itself" "required" "$last_out"

run -p "$work/definitely-missing"
assert_rc "non-existent path fails" 1
assert_contains "non-existent path explains itself" "does not exist" "$last_out"

d="$work/badflag"; mkdir -p "$d"
run -z -p "$d"
assert_rc "invalid flag fails" 1
assert_contains "invalid flag explains itself" "Invalid option" "$last_out"

# --- a failing R is reported, not swallowed --------------------------------
# renv setup failing must not be reported as a successful scaffold
d="$work/r-fails"; mkdir -p "$d"
run_with_path "$rshim" -l r -p "$d"
assert_rc "failing R fails" 1
assert_contains "failing R explains itself" "R failed" "$last_out"
assert_not_contains "failing R does not claim success" "successfully" "$last_out"

# --- a blocked target is reported, not swallowed ---------------------------
# A file where a directory belongs makes mkdir fail. The run must fail too
# instead of printing its success line.
d="$work/blocked"; mkdir -p "$d"; : > "$d/config"
run -p "$d"
assert_rc "blocked directory fails" 1
assert_not_contains "blocked directory does not claim success" "successfully" "$last_out"

# --- summary ---------------------------------------------------------------
printf '\n%d checks, %d failures\n' "$checks" "$failures"
[[ "$failures" -eq 0 ]]
