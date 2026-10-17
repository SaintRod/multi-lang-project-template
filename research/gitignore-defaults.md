---
date: 2026-10-17
updated: 2026-10-17
status: resolved
---

# Purpose

Document which sensible default `.gitignore` entries the project-creation
scripts should scaffold, and record the decision on how to structure them.

# Research

**Request:** add sensible defaults (such as `.env`) to the `.gitignore`
written during project creation, instead of creating an empty file.

**Findings:**

- `create-project.sh` and `create-project.ps1` currently `touch` an empty
  `.gitignore`
- The only exception is R, which appends `.Renviron` so credentials stay
  out of version control
- The template supports R, Python, and Julia, and the scripts already
  branch on `-l`, so language-specific ignores can be scoped per language
- `renv/` and `renv.lock` should stay tracked (`renv/` self-ignores its
  library)
- `Manifest.toml` is committed for apps/analysis and ignored for libraries
  — left out of the defaults
- `.env` should be ignored while `.env.example` stays tracked so the
  template is documented
- `data/output/` is a candidate for ignoring (derived data) but is
  opinionated for a data-analysis template — left out

**Candidate patterns:**

Universal:

- `.env`, `.env.*`, `!.env.example`
- `/.roborev/`
- `.DS_Store`, `Thumbs.db`, `Desktop.ini`
- `.vscode/`, `.idea/`, `*.swp`
- `*.log`

Python:

- `__pycache__/`, `*.py[cod]`
- `.venv/`, `venv/`
- `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`
- `.ipynb_checkpoints/`
- `*.egg-info/`, `dist/`, `build/`

R:

- `.Renviron`
- `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`

Julia:

- `*.jl.cov`, `*.jl.mem`

**Decision:** write a universal block for every project, then append a
language block based on `-l` (Python, R, or Julia), mirroring the existing
`.Renviron` branch. Appends must be idempotent so re-runs do not duplicate
lines. The universal block is always present because it covers secrets, OS
cruft, and editor files independent of language.

**Open questions:**

- Whether to also update the template repo's own `.gitignore`
- Whether to ignore `data/output/` in generated projects
