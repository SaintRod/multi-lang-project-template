---
date: 2026-10-17
status: open
---

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

# Purpose

Implement the decision in `research/gitignore-defaults.md`: scaffold a
universal `.gitignore` block in every generated project, then append a
language block chosen by `-l`. Both scripts (`create-project.sh`,
`create-project.ps1`) must stay in parity and appends must be idempotent.

Scope:

- Replace the R-only `.Renviron` append with a shared idempotent loop over
  universal + language-specific patterns
- Update the template repo's own `.gitignore` with the universal block
  (resolves open question 1: yes)
- Out of scope: ignoring `data/output/` (open question 2, stays left out)

Assumptions and risks:

- `pwsh` is not installed in the authoring environment, so Task 2's
  validation is deferred to a Windows or pwsh host. Its logic mirrors
  Task 1.
- Running `create-project.sh -l r` invokes R. Validation stubs `R` on PATH
  so the R tooling step is skipped and only `.gitignore` is exercised.
- The repo root `.gitignore` is currently untracked. Task 3 preserves its
  existing `/.roborev/` line and only adds patterns.

# Tasks

- [x] Task 1: universal + language `.gitignore` in `create-project.sh`
  [parallel: A]
  - File: `create-project.sh`
  - Lines: 96-102 (anchor:
    `if [[ "$lang" == "r" ]] && ! grep -qxF '.Renviron'`)
  - Change: replace the R-only `.Renviron` append with a shared
    idempotent loop over universal and language patterns
  - Before:
    ```bash
    # .Renviron holds credentials; keep it out of version control
    if [[ "$lang" == "r" ]] && ! grep -qxF '.Renviron' "$path/.gitignore"; then
        # Prepend a newline if the file lacks a trailing one, so we append a line
        # instead of gluing '.Renviron' onto an existing pattern
        [[ -s "$path/.gitignore" && -n "$(tail -c 1 "$path/.gitignore")" ]] && printf '\n' >> "$path/.gitignore"
        printf '.Renviron\n' >> "$path/.gitignore"
    fi
    ```
  - After:
    ```bash
    # Sensible default .gitignore entries.
    # Universal entries apply to every project; language entries are
    # appended based on -l. Appends are idempotent so re-runs do not
    # duplicate lines.
    gitignore_lines=(
        ".env"
        ".env.*"
        "!.env.example"
        "/.roborev/"
        ".DS_Store"
        "Thumbs.db"
        "Desktop.ini"
        ".vscode/"
        ".idea/"
        "*.swp"
        "*.log"
    )

    case "$lang" in
        r)
            gitignore_lines+=(
                ".Renviron"
                ".Rproj.user/"
                ".Rhistory"
                ".RData"
                ".Ruserdata"
            )
            ;;
        py|python)
            gitignore_lines+=(
                "__pycache__/"
                "*.py[cod]"
                ".venv/"
                "venv/"
                ".pytest_cache/"
                ".mypy_cache/"
                ".ruff_cache/"
                ".ipynb_checkpoints/"
                "*.egg-info/"
                "dist/"
                "build/"
            )
            ;;
        jl|julia)
            gitignore_lines+=("*.jl.cov" "*.jl.mem")
            ;;
    esac

    # Append each missing pattern, keeping existing content intact
    for line in "${gitignore_lines[@]}"; do
        if ! grep -qxF "$line" "$path/.gitignore"; then
            # Prepend a newline if the file lacks a trailing one, so we
            # append a line instead of gluing onto the previous one
            if [[ -s "$path/.gitignore" ]] &&
               [[ -n "$(tail -c 1 "$path/.gitignore")" ]]; then
                printf '\n' >> "$path/.gitignore"
            fi
            printf '%s\n' "$line" >> "$path/.gitignore"
        fi
    done
    ```
  - Expected result: generated `.gitignore` contains the universal block
    plus the language block; a second run adds nothing
  - Validate:
    ```bash
    tmp=$(mktemp -d); shim=$(mktemp -d)
    printf '#!/bin/sh\nexit 0\n' > "$shim/R"; chmod +x "$shim/R"
    PATH="$shim:$PATH" ./create-project.sh -l r -p "$tmp" >/dev/null
    a=$(wc -l < "$tmp/.gitignore")
    PATH="$shim:$PATH" ./create-project.sh -l r -p "$tmp" >/dev/null
    b=$(wc -l < "$tmp/.gitignore")
    cat "$tmp/.gitignore"; echo "before=$a after=$b"
    ```
    Success: output lists 16 lines (11 universal + 5 R) including
    `.Renviron`, and prints `before=16 after=16`.

- [x] Task 2: universal + language `.gitignore` in `create-project.ps1`
  [parallel: A]
  - File: `create-project.ps1`
  - Lines: 125-137 (anchor: `if ($lang -eq 'r') {` followed by
    `$gitignore = Join-Path`)
  - Change: replace the R-only `.Renviron` append with the same
    idempotent loop as Task 1
  - Before:
    ```powershell
    # .Renviron holds credentials; keep it out of version control
    if ($lang -eq 'r') {
        $gitignore = Join-Path -Path $targetPath -ChildPath '.gitignore'
        if (-not (Select-String -LiteralPath $gitignore -Pattern '^\.Renviron$' -Quiet)) {
            # Prepend a newline if the file lacks a trailing one, so we append a
            # line instead of gluing '.Renviron' onto an existing pattern
            $content = [System.IO.File]::ReadAllText($gitignore)
            if ($content -and -not $content.EndsWith("`n")) {
                Add-Content -LiteralPath $gitignore -Value ''
            }
            Add-Content -LiteralPath $gitignore -Value '.Renviron'
        }
    }
    ```
  - After:
    ```powershell
    # Sensible default .gitignore entries.
    # Universal entries apply to every project; language entries are
    # appended based on -l. Appends are idempotent so re-runs do not
    # duplicate lines.
    $gitignoreLines = @(
        '.env',
        '.env.*',
        '!.env.example',
        '/.roborev/',
        '.DS_Store',
        'Thumbs.db',
        'Desktop.ini',
        '.vscode/',
        '.idea/',
        '*.swp',
        '*.log'
    )

    switch ($lang) {
        'r' {
            $gitignoreLines += @(
                '.Renviron',
                '.Rproj.user/',
                '.Rhistory',
                '.RData',
                '.Ruserdata'
            )
            break
        }
        { $_ -in @('py', 'python') } {
            $gitignoreLines += @(
                '__pycache__/',
                '*.py[cod]',
                '.venv/',
                'venv/',
                '.pytest_cache/',
                '.mypy_cache/',
                '.ruff_cache/',
                '.ipynb_checkpoints/',
                '*.egg-info/',
                'dist/',
                'build/'
            )
            break
        }
        { $_ -in @('jl', 'julia') } {
            $gitignoreLines += @('*.jl.cov', '*.jl.mem')
            break
        }
    }

    $gitignore = Join-Path -Path $targetPath -ChildPath '.gitignore'
    foreach ($line in $gitignoreLines) {
        $pattern = '^' + [regex]::Escape($line) + '$'
        $found = Select-String -LiteralPath $gitignore -Pattern $pattern -Quiet
        if (-not $found) {
            # Prepend a newline if the file lacks a trailing one, so we
            # append a line instead of gluing onto the previous one
            $content = [System.IO.File]::ReadAllText($gitignore)
            if ($content -and -not $content.EndsWith("`n")) {
                Add-Content -LiteralPath $gitignore -Value ''
            }
            Add-Content -LiteralPath $gitignore -Value $line
        }
    }
    ```
  - Expected result: generated `.gitignore` matches Task 1; a second run
    adds nothing
  - Validate:
    ```powershell
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    .\create-project.ps1 -l py -p $tmp
    $a = (Get-Content (Join-Path $tmp '.gitignore')).Count
    .\create-project.ps1 -l py -p $tmp
    $b = (Get-Content (Join-Path $tmp '.gitignore')).Count
    Get-Content (Join-Path $tmp '.gitignore')
    "before=$a after=$b"
    ```
    Success: output lists 22 lines (11 universal + 11 Python) including
    `__pycache__/`, and prints `before=22 after=22`. Not runnable here
    (`pwsh` absent); run on a pwsh host.

- [x] Task 3: add universal block to the repo's own `.gitignore`
  [parallel: A]
  - File: `.gitignore`
  - Lines: 1-2 (anchor: `/.roborev/`)
  - Change: add the universal patterns while keeping the existing
    roborev entry
  - Before:
    ```gitignore
    # roborev snapshots
    /.roborev/
    ```
  - After:
    ```gitignore
    # roborev snapshots
    /.roborev/

    # Secrets
    .env
    .env.*
    !.env.example

    # OS cruft
    .DS_Store
    Thumbs.db
    Desktop.ini

    # Editor cruft
    .vscode/
    .idea/
    *.swp

    # Logs
    *.log
    ```
  - Expected result: repo ignores `.env` and OS/editor cruft, roborev
    entry retained
  - Validate:
    ```bash
    git check-ignore -v .env; grep -n 'roborev' .gitignore
    ```
    Success: `.env` reports the `.env` pattern from `.gitignore`, and
    grep shows `/.roborev/` still present.

## Commit

- [ ] Inspect status, diff, and recent commits
- [ ] Set `status: resolved` and `updated` in research/gitignore-defaults.md
- [ ] Stage only files relevant to this plan, including the plan and
  research files
- [ ] Commit without pushing
- [ ] Do not push. The user starts Roborev review manually
