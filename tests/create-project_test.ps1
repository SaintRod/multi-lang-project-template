#!/usr/bin/env pwsh
# Characterization tests for create-project.ps1.
# Mirror of tests/create-project_test.sh, run on the same cases.
# Run: pwsh -NoProfile -File tests/create-project_test.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$create = Join-Path (Split-Path -Parent $here) 'create-project.ps1'
$pwshExe = if ($IsWindows) { Join-Path $PSHOME 'pwsh.exe' }
           else { Join-Path $PSHOME 'pwsh' }

$script:checks = 0
$script:failures = 0

function Ok([string]$name) { $script:checks++; Write-Host "ok   $name" }
function No([string]$name) { $script:checks++; $script:failures++; Write-Host "FAIL $name" }

function Assert-Dir([string]$name, [string]$path) {
    if (Test-Path -LiteralPath $path -PathType Container) { Ok $name }
    else { No "$name (missing dir: $path)" }
}
function Assert-NoDir([string]$name, [string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { Ok $name }
    else { No "$name (unexpected path: $path)" }
}
function Assert-File([string]$name, [string]$path) {
    if (Test-Path -LiteralPath $path -PathType Leaf) { Ok $name }
    else { No "$name (missing file: $path)" }
}
function Assert-Line([string]$name, [string]$pattern, [string]$file) {
    $regex = '^' + [regex]::Escape($pattern) + '$'
    if (Select-String -LiteralPath $file -Pattern $regex -Quiet) { Ok $name }
    else { No "$name (missing line '$pattern' in $file)" }
}
function Assert-NoLine([string]$name, [string]$pattern, [string]$file) {
    $regex = '^' + [regex]::Escape($pattern) + '$'
    if (Select-String -LiteralPath $file -Pattern $regex -Quiet) {
        No "$name (unexpected line '$pattern' in $file)"
    } else { Ok $name }
}
function Assert-Eq([string]$name, $actual, $expected) {
    if ("$actual" -eq "$expected") { Ok $name }
    else { No "$name (expected '$expected', got '$actual')" }
}
function Assert-Contains([string]$name, [string]$needle, [string]$haystack) {
    if ($haystack.Contains($needle)) { Ok $name }
    else { No "$name (missing '$needle' in output: $haystack)" }
}
function Assert-NonZero([string]$name) {
    if ($script:lastRc -ne 0) { Ok $name }
    else { No "$name (expected non-zero exit, got $script:lastRc)" }
}
function Assert-Rc([string]$name, [int]$expected) {
    if ($script:lastRc -eq $expected) { Ok $name }
    else { No "$name (expected exit $expected, got $script:lastRc)" }
}

# Run create-project.ps1 in a child pwsh. A child process keeps its
# `exit 1` from terminating this test run.
$script:lastRc = 0
$script:lastOut = ''
function Invoke-Create([string[]]$CreateArgs) {
    $script:lastOut = (& $pwshExe -NoProfile -File $create @CreateArgs 2>&1 | Out-String)
    $script:lastRc = $LASTEXITCODE
}

function New-WorkDir([string]$name) {
    $dir = Join-Path $script:work $name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

$script:work = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
New-Item -ItemType Directory -Path $script:work | Out-Null

try {
    $defaultDirs = @(
        'data', 'data/input', 'data/output', 'documentation', 'config',
        'notebooks', 'src', 'scripts', 'research', 'plans', 'handoffs'
    )

    # --- no -l: every default dir plus both test dirs ---------------------
    $d = New-WorkDir 'nolang'
    Invoke-Create @('-p', $d)
    Assert-Rc "no -l exits 0" 0
    foreach ($dir in $defaultDirs) {
        Assert-Dir "no -l creates $dir" (Join-Path $d $dir)
    }
    Assert-Dir "no -l creates test" (Join-Path $d 'test')
    Assert-Dir "no -l creates tests" (Join-Path $d 'tests')
    Assert-File "no -l creates .gitignore" (Join-Path $d '.gitignore')
    Assert-File "no -l creates LICENSE" (Join-Path $d 'LICENSE')
    Assert-File "no -l creates README.md" (Join-Path $d 'README.md')
    $gi = Join-Path $d '.gitignore'
    Assert-Line "no -l ignores .env" '.env' $gi
    Assert-NoLine "no -l has no R block" '.Renviron' $gi
    Assert-NoLine "no -l has no Python block" '__pycache__/' $gi
    Assert-NoLine "no -l has no Julia block" '*.jl.cov' $gi

    # --- -l r -------------------------------------------------------------
    $d = New-WorkDir 'r'
    Invoke-Create @('-l', 'r', '-p', $d)
    $gi = Join-Path $d '.gitignore'
    Assert-Rc "-l r exits 0" 0
    Assert-Dir "-l r creates tests" (Join-Path $d 'tests')
    Assert-NoDir "-l r omits test" (Join-Path $d 'test')
    Assert-File "-l r creates .Renviron" (Join-Path $d '.Renviron')
    Assert-Line "-l r ignores .Renviron" '.Renviron' $gi
    Assert-Line "-l r ignores .Rhistory" '.Rhistory' $gi
    Assert-NoLine "-l r has no Python block" '__pycache__/' $gi
    Assert-Eq "-l r gitignore is 16 lines" (Get-Content $gi).Count 16

    # --- -l py / -l python ------------------------------------------------
    foreach ($lang in @('py', 'python')) {
        $d = New-WorkDir $lang
        Invoke-Create @('-l', $lang, '-p', $d)
        $gi = Join-Path $d '.gitignore'
        Assert-Rc "-l $lang exits 0" 0
        Assert-Dir "-l $lang creates tests" (Join-Path $d 'tests')
        Assert-NoDir "-l $lang omits test" (Join-Path $d 'test')
        Assert-Line "-l $lang ignores __pycache__/" '__pycache__/' $gi
        Assert-Line "-l $lang ignores .venv/" '.venv/' $gi
        Assert-NoLine "-l $lang has no R block" '.Renviron' $gi
        Assert-NoLine "-l $lang has no Julia block" '*.jl.cov' $gi
        Assert-Eq "-l $lang gitignore is 22 lines" (Get-Content $gi).Count 22
    }

    # --- -l jl / -l julia -------------------------------------------------
    foreach ($lang in @('jl', 'julia')) {
        $d = New-WorkDir $lang
        Invoke-Create @('-l', $lang, '-p', $d)
        $gi = Join-Path $d '.gitignore'
        Assert-Rc "-l $lang exits 0" 0
        Assert-Dir "-l $lang creates test" (Join-Path $d 'test')
        Assert-NoDir "-l $lang omits tests" (Join-Path $d 'tests')
        Assert-Line "-l $lang ignores *.jl.cov" '*.jl.cov' $gi
        Assert-NoLine "-l $lang has no Python block" '__pycache__/' $gi
    }

    # --- -l is case-insensitive -------------------------------------------
    $d = New-WorkDir 'upper-r'
    Invoke-Create @('-l', 'R', '-p', $d)
    Assert-Rc "-l R exits 0" 0
    Assert-File "-l R creates .Renviron" (Join-Path $d '.Renviron')
    Assert-NoDir "-l R omits test" (Join-Path $d 'test')

    $d = New-WorkDir 'upper-py'
    Invoke-Create @('-l', 'PYTHON', '-p', $d)
    Assert-Dir "-l PYTHON creates tests" (Join-Path $d 'tests')
    Assert-NoDir "-l PYTHON omits test" (Join-Path $d 'test')

    $d = New-WorkDir 'mixed-jl'
    Invoke-Create @('-l', 'Julia', '-p', $d)
    Assert-Dir "-l Julia creates test" (Join-Path $d 'test')
    Assert-NoDir "-l Julia omits tests" (Join-Path $d 'tests')

    # --- re-runs are idempotent -------------------------------------------
    $d = New-WorkDir 'idempotent'
    Invoke-Create @('-l', 'py', '-p', $d)
    $gi = Join-Path $d '.gitignore'
    $first = (Get-Content $gi).Count
    Invoke-Create @('-l', 'py', '-p', $d)
    $second = (Get-Content $gi).Count
    Assert-Eq "second run adds no gitignore lines" $second $first
    Assert-Eq "no duplicate .env lines" `
        @(Select-String -LiteralPath $gi -Pattern '^\.env$').Count 1

    # --- existing .gitignore content is preserved -------------------------
    $d = New-WorkDir 'preserve'
    $gi = Join-Path $d '.gitignore'
    [System.IO.File]::WriteAllText($gi, "my-custom/`n.env`n")
    Invoke-Create @('-l', 'py', '-p', $d)
    Assert-Rc "-l py over existing .gitignore exits 0" 0
    Assert-Line "preserves custom pattern" 'my-custom/' $gi
    Assert-Eq "does not duplicate existing .env" `
        @(Select-String -LiteralPath $gi -Pattern '^\.env$').Count 1

    # --- .gitignore without a trailing newline ----------------------------
    $d = New-WorkDir 'nonewline'
    $gi = Join-Path $d '.gitignore'
    [System.IO.File]::WriteAllText($gi, 'custom-line')
    Invoke-Create @('-l', 'r', '-p', $d)
    Assert-Line "preserves unterminated line" 'custom-line' $gi
    Assert-Line "appends .env on its own line" '.env' $gi
    Assert-NoLine "does not glue onto previous line" 'custom-line.env' $gi

    # --- unknown -l falls back to both test dirs --------------------------
    $d = New-WorkDir 'unknown'
    Invoke-Create @('-l', 'go', '-p', $d)
    Assert-Rc "-l go exits 0" 0
    Assert-Dir "-l go creates test" (Join-Path $d 'test')
    Assert-Dir "-l go creates tests" (Join-Path $d 'tests')

    # --- error paths ------------------------------------------------------
    Invoke-Create @('-l', 'py')
    Assert-NonZero "missing -p fails"

    $missing = Join-Path $script:work 'definitely-missing'
    Invoke-Create @('-p', $missing)
    Assert-NonZero "non-existent path fails"
    Assert-Contains "non-existent path explains itself" 'does not exist' $script:lastOut

    $d = New-WorkDir 'badflag'
    Invoke-Create @('-z', '-p', $d)
    Assert-NonZero "invalid flag fails"
} finally {
    Remove-Item -Recurse -Force $script:work -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "$script:checks checks, $script:failures failures"
if ($script:failures -eq 0) { exit 0 } else { exit 1 }
