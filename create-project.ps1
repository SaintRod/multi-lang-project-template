<#
.SYNOPSIS
  Creates a standardized, language-agnostic data-analysis project file structure on Windows.

.DESCRIPTION
  PowerShell translation of create-project.sh.

  Purpose: create folders and placeholder files only (no language-specific tooling).

  - Creates directories:
      data, data/input, data/output, docs, config, notebooks, src, scripts
    plus language-specific test folders:
      * R / Python  -> tests
      * Julia       -> test
      * unspecified -> test and tests

  - Creates files:
      .gitignore, LICENSE, README.md


.PARAMETER Language
  Language selector. Accepted (case-insensitive): r, py, python, jl, julia.

.PARAMETER Path
  Existing directory path where the structure will be created.
  Required. Use -p . to target the current directory explicitly.

.EXAMPLE
  .\create-project.ps1 -p .

.EXAMPLE
  .\create-project.ps1 -l python -p C:\work\myproj

.EXAMPLE
  # If script execution is blocked:
  powershell -ExecutionPolicy Bypass -File .\create-project.ps1 -l r -p C:\work\myproj
#>

[CmdletBinding()]
param(
    [Alias('l')]
    [string]$Language = '',

    [Alias('p')]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [switch]$Help
)

if ($Help) {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
    return
}

function To-Lower([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return '' }
    return $s.ToLowerInvariant()
}

$lang = To-Lower $Language
$targetPath = $Path

if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
    Write-Error "Error: The specified path '$targetPath' does not exist."
    exit 1
}

# Resolve to a full path for cleaner output and for downstream tooling
$targetPath = (Resolve-Path -LiteralPath $targetPath).Path

# Default directories
$dirs = @(
    'data',
    'data/input',
    'data/output',
    'docs',
    'config',
    'notebooks',
    'src',
    'scripts'
)

# Define files
$files = @(
    '.gitignore',
    'LICENSE',
    'README.md'
)

# Adjust directories based on language flag
switch ($lang) {
    { $_ -in @('r','py','python') } { $dirs += 'tests' ; break }
    { $_ -in @('jl','julia') }       { $dirs += 'test'  ; break }
    default                          { $dirs += @('test','tests') }
}

Write-Host "Creating directories at $targetPath..."
foreach ($dir in $dirs) {
    $fullDir = Join-Path -Path $targetPath -ChildPath $dir
    New-Item -ItemType Directory -Path $fullDir -Force | Out-Null
    Write-Host "Created $fullDir"
}

Write-Host "Creating files at $targetPath..."
foreach ($file in $files) {
    $fullFile = Join-Path -Path $targetPath -ChildPath $file
    if (-not (Test-Path -LiteralPath $fullFile -PathType Leaf)) {
        New-Item -ItemType File -Path $fullFile -Force | Out-Null
    } else {
        # Keep existing file; touch equivalent by updating LastWriteTime
        (Get-Item -LiteralPath $fullFile).LastWriteTime = Get-Date
    }
    Write-Host "Created $fullFile"
}

Write-Host "Project structure created successfully at $targetPath!"