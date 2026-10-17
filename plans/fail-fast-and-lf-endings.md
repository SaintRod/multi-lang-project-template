---
date: 2026-10-17
updated: 2026-10-17
status: resolved
---

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

# Purpose

Fix two problems found while reviewing the repo after adding CI.

1. Both scaffold scripts report success after failing. `create-project.sh`
   has no `set -e`, so a failed `mkdir`, `touch`, or `R -e` falls through
   to `Project structure created successfully` and exit 0.
   `create-project.ps1` never sets `$ErrorActionPreference`, so the same
   lie happens for a failed `New-Item` or `Add-Content`.
2. Nothing pins shell scripts to LF, so a Windows checkout with
   `core.autocrlf=true` can turn `create-project.sh` into a file whose
   `#!/bin/bash` shebang cannot be executed.

Evidence collected before planning, all reproduced in this session:

- bash, failing `R` stub on PATH:
  `./create-project.sh -l r -p "$tmp"` prints nothing on stderr, prints
  `Project structure created successfully at ...`, and exits 0
- PowerShell, read-only target directory:
  `create-project.ps1 -p <read-only dir>` prints
  `Project structure created successfully at ...` and exits 0
- both suites are green at 79 checks before any change
- `New-Item -ItemType Directory -Force` does **not** fail when a file of
  the same name exists, so a name conflict is not a usable failure trigger
- `$ErrorActionPreference = 'Stop'` makes the existing `Write-Error` guard
  at `create-project.ps1:69` terminate with exit code 1 and still emit
  `does not exist`, so the existing guard assertions keep passing
- `pwsh` 7.4.6 is available at `/tmp/opencode/pwsh/pwsh`, so the
  PowerShell half is validated here rather than deferred

Scope:

- `create-project.sh`: fail fast, and report a failed R run
- `create-project.ps1`: fail fast
- both test suites: cover the new failure paths
- `.gitattributes`: pin `*.sh` to LF

Out of scope, named so they are not re-litigated:

- `Set-StrictMode -Version Latest` in `create-project.ps1`. It does not fix
  the false-success bug and it changes semantics beyond the failure path
- `repos='http://cran.us.r-project.org'` is plain HTTP. A real but separate
  concern, left alone
- The CI Windows job, template-repo toggle, ShellCheck, workflow
  `permissions`/`concurrency`, and Dependabot. Discussed, not approved

Assumptions and risks:

- The PowerShell read-only test needs Unix file modes, so it is guarded by
  `if (-not $IsWindows)`. If the CI Windows job is added later, the guard
  already keeps it from breaking
- CI runners and the authoring machine both run as a non-root user, so a
  read-only directory is genuinely unwritable. Under root the mode is
  bypassed, the scaffold succeeds, and the read-only checks fail loudly
  rather than passing silently
- `set -e` changes behavior on every failure path. The risk is a script
  that aborts where it previously limped on. That is the intent, and the
  existing 79-check suite guards the success paths

# Tasks

- [x] Task 1: pin shell scripts to LF
  [parallel: A]
  - File: `.gitattributes`
  - Lines: new file
  - Change: force LF for shell scripts so a CRLF checkout cannot break the
    `create-project.sh` shebang
  - After:
    ```
    # Shell scripts must keep LF endings: create-project.sh is run via its
    # shebang, and a CRLF checkout makes it fail with "bad interpreter"
    *.sh text eol=lf
    ```
  - Expected result: git reports `eol: lf` for shell scripts, and no file
    in the tree is renormalized (everything is already LF)
  - Validate:
    ```bash
    git check-attr eol -- create-project.sh tests/create-project_test.sh
    git status --porcelain
    ```
    Success: both paths report `eol: lf`, and `git status` lists only
    `.gitattributes` (no renormalization churn)

- [x] Task 2: cover a failing R in the bash suite
  [parallel: A]
  - File: `tests/create-project_test.sh`
  - Lines: 22, 28-32, 36-44, 161-164 (anchors: `assert_rc() {`,
    `run() {`, `trap 'rm -rf "$work" "$shim"' EXIT`,
    `assert_contains "invalid flag explains itself"`)
  - Change: add a `not contains` assertion, a `run_with_path` helper, a
    stub R that exits 1, and a case asserting a failing R fails the run
  - Before:
    ```bash
    assert_contains() { [[ "$3" == *"$2"* ]] && ok "$1" || no "$1 (missing '$2' in output: $3)"; }
    assert_rc() { [[ "$last_rc" == "$2" ]] && ok "$1" || no "$1 (expected exit $2, got $last_rc)"; }
    ```
  - After:
    ```bash
    assert_contains() { [[ "$3" == *"$2"* ]] && ok "$1" || no "$1 (missing '$2' in output: $3)"; }
    assert_not_contains() { [[ "$3" != *"$2"* ]] && ok "$1" || no "$1 (unexpected '$2' in output: $3)"; }
    assert_rc() { [[ "$last_rc" == "$2" ]] && ok "$1" || no "$1 (expected exit $2, got $last_rc)"; }
    ```
  - Before:
    ```bash
    run() {
        last_rc=0
        last_out=$("$create" "$@" 2>&1) || last_rc=$?
        return 0
    }
    ```
  - After:
    ```bash
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
    ```
  - Before:
    ```bash
    shim=$(mktemp -d)
    printf '#!/bin/sh\nexit 0\n' > "$shim/R"
    chmod +x "$shim/R"
    PATH="$shim:$PATH"

    work=$(mktemp -d)
    # Stay inside the trap-cleaned dir so a CWD-relative scaffold can't escape it.
    cd "$work"
    trap 'rm -rf "$work" "$shim"' EXIT
    ```
  - After:
    ```bash
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
    ```
  - Before:
    ```bash
    d="$work/badflag"; mkdir -p "$d"
    run -z -p "$d"
    assert_rc "invalid flag fails" 1
    assert_contains "invalid flag explains itself" "Invalid option" "$last_out"
    ```
  - After:
    ```bash
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
    ```
  - Expected result: 3 new checks, and all three FAIL against the
    unmodified script
  - Validate:
    ```bash
    bash tests/create-project_test.sh; echo "rc=$?"
    ```
    Success before Task 3: `failing R fails`, `failing R explains itself`,
    and `failing R does not claim success` all report FAIL, and rc is 1.
    Success after Task 3: 82 checks, 0 failures, rc 0

- [x] Task 3: fail fast and report a failed R in `create-project.sh`
  [after: 2]
  - File: `create-project.sh`
  - Lines: 1-2, 157-169 (anchors: `#!/bin/bash`,
    ` if [[ "$lang" == "r" && -n "$path" ]]; then`)
  - Change: abort on the first unchecked failure, and turn a failed or
    missing R into a clear error with a non-zero exit
  - Before:
    ```bash
    #!/bin/bash

    # Default directories
    ```
  - After:
    ```bash
    #!/bin/bash
    # Fail fast: a failed mkdir/touch/R call must abort instead of falling
    # through to the success message at the end
    set -euo pipefail

    # Default directories
    ```
  - Before:
    ```bash
     if [[ "$lang" == "r" && -n "$path" ]]; then
       R -e "
       if (!require('renv', quietly = TRUE)){
         install.packages('renv', repos='http://cran.us.r-project.org')}
       
       renv::init(project = '$path')
       q(save = 'no')"
     fi
    ```
  - After:
    ```bash
    if [[ "$lang" == "r" && -n "$path" ]]; then
      # A missing or failing R must fail the run, not print a success message
      if ! R -e "
      if (!require('renv', quietly = TRUE)){
        install.packages('renv', repos='http://cran.us.r-project.org')}

      renv::init(project = '$path')
      q(save = 'no')"; then
        echo "Error: R failed; project setup is incomplete." >&2
        exit 1
      fi
    fi
    ```
  - Expected result: the suite goes green, and a failing R exits 1 with
    `R failed` on stderr and no success line
  - Validate:
    ```bash
    bash tests/create-project_test.sh; echo "rc=$?"
    ```
    Success: 82 checks, 0 failures, rc 0 (84 once Task 7 lands)

- [x] Task 4: cover a blocked target in the PowerShell suite
  [parallel: A]
  - File: `tests/create-project_test.ps1`
  - Lines: 46-49, 195 (anchors: `function Assert-Contains`,
    `# --- error paths ---`)
  - Change: add a `not contains` assertion and a read-only-target case
    asserting the run fails and does not claim success
  - Before:
    ```powershell
    function Assert-Contains([string]$name, [string]$needle, [string]$haystack) {
        if ($haystack.Contains($needle)) { Ok $name }
        else { No "$name (missing '$needle' in output: $haystack)" }
    }
    ```
  - After:
    ```powershell
    function Assert-Contains([string]$name, [string]$needle, [string]$haystack) {
        if ($haystack.Contains($needle)) { Ok $name }
        else { No "$name (missing '$needle' in output: $haystack)" }
    }
    function Assert-NotContains([string]$name, [string]$needle, [string]$haystack) {
        if (-not $haystack.Contains($needle)) { Ok $name }
        else { No "$name (unexpected '$needle' in output: $haystack)" }
    }
    ```
  - Before:
    ```powershell
        # --- error paths ------------------------------------------------------
        Invoke-Create @('-l', 'py')
    ```
  - After:
    ```powershell
        # --- a blocked target is reported, not swallowed ----------------------
        # A read-only target makes every New-Item fail. The run must fail too
        # instead of printing its success line. Unix-only: Windows needs ACLs.
        if (-not $IsWindows) {
            $d = New-WorkDir 'readonly'
            [System.IO.File]::SetUnixFileMode($d,
                [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserExecute)
            Invoke-Create @('-p', $d)
            Assert-NonZero "read-only target fails"
            Assert-NotContains "read-only target does not claim success" 'successfully' $script:lastOut
            [System.IO.File]::SetUnixFileMode($d,
                [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
        }

        # --- error paths ------------------------------------------------------
        Invoke-Create @('-l', 'py')
    ```
  - Expected result: 2 new checks that FAIL against the unmodified script
  - Validate:
    ```bash
    /tmp/opencode/pwsh/pwsh -NoProfile -File tests/create-project_test.ps1; echo "rc=$?"
    ```
    Success before Task 5: `read-only target fails` and
    `read-only target does not claim success` both report FAIL, rc 1.
    Success after Task 5: 81 checks, 0 failures, rc 0
  - Implementation note: `[System.IO.UnixFileMode]::UserReadWriteExecute`
    does not exist. The restore uses an explicit `-bor` of `UserRead`,
    `UserWrite`, and `UserExecute`

- [x] Task 5: fail fast in `create-project.ps1`
  [after: 4]
  - File: `create-project.ps1`
  - Lines: 68-74 (anchor: `does not exist.` guard, then
    `# Resolve to a full path`)
  - Change: make cmdlet failures terminate so the run cannot reach the
    success line after a failed `New-Item` or `Add-Content`
  - Before:
    ```powershell
    if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
        Write-Error "Error: The specified path '$targetPath' does not exist."
        exit 1
    }

    # Resolve to a full path for cleaner output and for downstream tooling
    ```
  - After:
    ```powershell
    if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
        Write-Error "Error: The specified path '$targetPath' does not exist."
        exit 1
    }

    # Fail fast: a failed New-Item/Add-Content must abort instead of falling
    # through to the success message at the end. Deliberately set after the
    # path guard above so that guard keeps its single-line error message
    $ErrorActionPreference = 'Stop'

    # Resolve to a full path for cleaner output and for downstream tooling
    ```
  - Expected result: the suite goes green, and a read-only target exits
    non-zero without a success line
  - Validate:
    ```bash
    /tmp/opencode/pwsh/pwsh -NoProfile -File tests/create-project_test.ps1; echo "rc=$?"
    ```
    Success: 81 checks, 0 failures, rc 0
  - Implementation note: the plan first placed the assignment at the top of
    the script. That turned the guard's non-terminating `Write-Error` into a
    terminating error, which PowerShell renders as a multi-line block.
    `Out-String` wraps at 80 columns, splitting `does not exist` across two
    lines and breaking the existing assertion at line 203. Setting the
    preference after the guard keeps the guard's output byte-identical

- [x] Task 6: let the PowerShell re-run path see dot-files
  [after: 5]
  - File: `create-project.ps1`
  - Lines: 121-122 (anchor: `touch equivalent by updating
    LastWriteTime`)
  - Change: pass `-Force` so `Get-Item` can see `.gitignore` and
    `.Renviron`, which PowerShell treats as hidden on Unix
  - Before:
    ```powershell
        # Keep existing file; touch equivalent by updating LastWriteTime
        (Get-Item -LiteralPath $fullFile).LastWriteTime = Get-Date
    ```
  - After:
    ```powershell
        # Keep existing file; touch equivalent by updating LastWriteTime
        # -Force: PowerShell treats dot-files as hidden on Unix
        (Get-Item -LiteralPath $fullFile -Force).LastWriteTime = Get-Date
    ```
  - Expected result: re-running against an existing `.gitignore` exits 0
  - Validate:
    ```bash
    /tmp/opencode/pwsh/pwsh -NoProfile -File tests/create-project_test.ps1; echo "rc=$?"
    ```
    Success: 81 checks, 0 failures, rc 0, including
    `-l py over existing .gitignore exits 0` and
    `appends .env on its own line`
  - Implementation note: this is a pre-existing latent bug that Task 5
    surfaced. `Get-Item -LiteralPath <dot-file>` fails with
    `Could not find item` on Unix without `-Force`, because PowerShell
    marks dot-files hidden. `ErrorActionPreference = 'Continue'` swallowed
    it, so the "touch" never actually happened and nobody noticed. With
    `Stop` it became a hard failure, which broke the two re-run cases. The
    existing suite caught the regression, so no new test was needed

- [x] Task 7: pin the bash mkdir fail-fast with a test
  [after: 6]
  - File: `tests/create-project_test.sh`
  - Lines: 186 (anchor: `assert_not_contains "failing R does not claim
    success"`)
  - Change: cover the mkdir failure path, which the R test alone does not
    pin
  - Before:
    ```bash
    assert_not_contains "failing R does not claim success" "successfully" "$last_out"
    ```
  - After:
    ```bash
    assert_not_contains "failing R does not claim success" "successfully" "$last_out"

    # --- a blocked target is reported, not swallowed ---------------------------
    # A file where a directory belongs makes mkdir fail. The run must fail too
    # instead of printing its success line.
    d="$work/blocked"; mkdir -p "$d"; : > "$d/config"
    run -p "$d"
    assert_rc "blocked directory fails" 1
    assert_not_contains "blocked directory does not claim success" "successfully" "$last_out"
    ```
  - Expected result: 2 new checks that FAIL when `set -euo pipefail` is
    removed from `create-project.sh`
  - Validate:
    ```bash
    bash tests/create-project_test.sh; echo "rc=$?"
    ```
    Success: 84 checks, 0 failures, rc 0
  - Implementation note: added in response to the final review, which found
    that Task 3's `set -e` behavior was pinned only for the R path. Deleting
    `set -euo pipefail` on its own left the suite green while the mkdir bug
    returned. Verified by mutation: with the line removed the two new checks
    fail (`84 checks, 2 failures`); with it restored, 84 pass. A
    name-conflict trigger is used rather than the ps1 suite's read-only
    directory, so the check does not depend on the running user and stays
    honest under root

## Commit

- [x] Inspect status, diff, and recent commits
- [x] Set `status: resolved` and `updated: 2026-10-17` in this plan
- [x] Stage only files relevant to this plan, including the plan file
- [x] Commit without pushing
- [ ] Do not push. The user starts Roborev review manually
