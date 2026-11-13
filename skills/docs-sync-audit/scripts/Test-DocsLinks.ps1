<#
.SYNOPSIS
  Read-only check of Markdown docs for facts a script can prove.
.DESCRIPTION
  Checks relative Markdown links (file and #heading anchor) and optionally
  SKILL.md names and PowerShell code blocks. It writes nothing to the repository.
  It never judges prose: use its output as leads, then confirm in the source.
  Exit code: 0 = no findings, 1 = findings, 2 = bad input.
.PARAMETER Root
  Folder to scan. Default: the current folder.
.PARAMETER Exclude
  Folder names to skip, in addition to .git, node_modules, .todo, .workspace and __pycache__.
.PARAMETER CheckSkills
  Also check that each SKILL.md has name and description, that name matches its folder, and that the description is 1024 characters or fewer.
.PARAMETER CheckPowerShell
  Also parse ```powershell code blocks. Placeholders such as <name> cause false positives.
.PARAMETER Format
  Text (default) or Json.
.EXAMPLE
  pwsh -NoProfile -File .\Test-DocsLinks.ps1 -Root C:\repo -CheckSkills
#>
[CmdletBinding()]
param(
    [string]$Root = '.',
    [string[]]$Exclude = @(),
    [switch]$CheckSkills,
    [switch]$CheckPowerShell,
    [ValidateSet('Text', 'Json')]
    [string]$Format = 'Text'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Error "Root folder not found: $Root"
    exit 2
}
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$skip = @('.git', 'node_modules', '.todo', '.workspace', '__pycache__') + $Exclude
$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param([string]$File, [int]$Line, [string]$Kind, [string]$Detail)
    $relative = [System.IO.Path]::GetRelativePath($rootPath, $File)
    $findings.Add([pscustomobject]@{ File = $relative; Line = $Line; Kind = $Kind; Detail = $Detail })
}

function Test-Skipped {
    param([string]$FullName)
    $parts = [System.IO.Path]::GetRelativePath($rootPath, $FullName).Split([char[]]@('\', '/'))
    [bool]($parts | Select-Object -SkipLast 1 | Where-Object { $_ -in $skip })
}

# Returns lines outside code fences as @{ Number; Text }, plus the fenced blocks.
function Read-Markdown {
    param([string]$Path)
    $outside = [System.Collections.Generic.List[object]]::new()
    $blocks = [System.Collections.Generic.List[object]]::new()
    $fence = $null
    $number = 0
    foreach ($text in [System.IO.File]::ReadLines($Path)) {
        $number++
        if ($null -eq $fence) {
            if ($text -match '^\s*(`{3,}|~{3,})\s*([A-Za-z0-9_+-]*)') {
                $fence = @{ Marker = $Matches[1]; Lang = $Matches[2]; Start = $number; Lines = [System.Collections.Generic.List[string]]::new() }
            } else {
                $outside.Add(@{ Number = $number; Text = $text })
            }
        } elseif ($text -match ('^\s*' + [regex]::Escape([string]$fence.Marker[0]) + '{' + $fence.Marker.Length + ',}\s*$')) {
            $blocks.Add($fence)
            $fence = $null
        } else {
            $fence.Lines.Add($text)
        }
    }
    [pscustomobject]@{ Outside = $outside; Blocks = $blocks }
}

# GitHub heading slug: lowercase, drop punctuation, spaces to hyphens, -N for repeats.
function Get-HeadingSlug {
    param($Doc)
    $seen = @{}
    $slugs = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($line in $Doc.Outside) {
        if ($line.Text -match '^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$') {
            $title = $Matches[1] -replace '\[([^\]]*)\]\([^)]*\)', '$1' -replace '[`*_~]', ''
            $slug = ($title.ToLowerInvariant() -replace '[^\p{L}\p{N}\- ]', '') -replace ' ', '-'
            if ($seen.ContainsKey($slug)) {
                $seen[$slug]++
                $slug = '{0}-{1}' -f $slug, $seen[$slug]
            } else {
                $seen[$slug] = 0
            }
            [void]$slugs.Add($slug)
        }
    }
    , $slugs
}

$docs = @{}
foreach ($file in Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter '*.md') {
    if (-not (Test-Skipped $file.FullName)) { $docs[$file.FullName] = Read-Markdown -Path $file.FullName }
}
$slugCache = @{}
$linkPattern = '(?<!!)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)|!\[[^\]]*\]\(\s*<?([^)\s>]+)>?'

foreach ($path in $docs.Keys) {
    $directory = Split-Path -Parent $path
    foreach ($line in $docs[$path].Outside) {
        $text = $line.Text -replace '`[^`]*`', ''
        foreach ($match in [regex]::Matches($text, $linkPattern)) {
            $target = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
            if ($target -match '^[A-Za-z][A-Za-z0-9+.-]*:' -or $target.StartsWith('//')) { continue }
            $filePart, $anchor = $target -split '#', 2
            $filePart = [uri]::UnescapeDataString($filePart)
            $resolved = if ($filePart) { [System.IO.Path]::GetFullPath((Join-Path $directory $filePart)) } else { $path }
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Finding $path $line.Number 'broken-link' "Target not found: $target"
                continue
            }
            if ($anchor -and $resolved -like '*.md' -and (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                if (-not $slugCache.ContainsKey($resolved)) {
                    $doc = if ($docs.ContainsKey($resolved)) { $docs[$resolved] } else { Read-Markdown -Path $resolved }
                    $slugCache[$resolved] = Get-HeadingSlug -Doc $doc
                }
                if (-not $slugCache[$resolved].Contains($anchor.ToLowerInvariant())) {
                    Add-Finding $path $line.Number 'broken-anchor' "No heading for #$anchor in $([System.IO.Path]::GetRelativePath($rootPath, $resolved))"
                }
            }
        }
    }

    if ($CheckPowerShell) {
        foreach ($block in $docs[$path].Blocks | Where-Object { $_.Lang -in 'powershell', 'pwsh', 'ps1' }) {
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseInput(($block.Lines -join "`n"), [ref]$null, [ref]$errors)
            if ($errors) {
                Add-Finding $path $block.Start 'powershell-syntax' "Lead: $($errors[0].Message)"
            }
        }
    }
}

if ($CheckSkills) {
    foreach ($skill in Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter 'SKILL.md') {
        if (Test-Skipped $skill.FullName) { continue }
        $raw = Get-Content -LiteralPath $skill.FullName -Raw
        if ($raw -notmatch '(?s)\A---\r?\n(.*?)\r?\n---') {
            Add-Finding $skill.FullName 1 'skill-frontmatter' 'Missing YAML frontmatter'
            continue
        }
        $front = $Matches[1]
        $name = if ($front -match '(?m)^name:\s*["'']?([^"''\r\n]+?)["'']?\s*$') { $Matches[1] } else { $null }
        if (-not $name) { Add-Finding $skill.FullName 1 'skill-frontmatter' 'Missing name'; continue }
        if ($front -notmatch '(?m)^description:\s*\S') { Add-Finding $skill.FullName 1 'skill-frontmatter' 'Missing description' }
        $descriptionLine = [regex]::Match($front, '(?m)^description:\s*(.+)$')
        if ($descriptionLine.Success -and $descriptionLine.Groups[1].Value.Trim('"', "'").Length -gt 1024) {
            Add-Finding $skill.FullName 1 'skill-description' 'Description is longer than 1024 characters'
        }
        if ($name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $name.Length -gt 64) {
            Add-Finding $skill.FullName 1 'skill-name' "Name '$name' must be lowercase words joined by hyphens, 64 characters at most"
        }
        if ($name -ne $skill.Directory.Name) {
            Add-Finding $skill.FullName 1 'skill-name' "Name '$name' does not match folder '$($skill.Directory.Name)'"
        }
    }
}

$sorted = @($findings | Sort-Object File, Line)
if ($Format -eq 'Json') {
    ConvertTo-Json -InputObject $sorted -AsArray
} else {
    $sorted | ForEach-Object { '{0}:{1} [{2}] {3}' -f $_.File, $_.Line, $_.Kind, $_.Detail }
    Write-Output ('{0} Markdown files scanned, {1} findings.' -f $docs.Count, $sorted.Count)
}
exit $(if ($sorted.Count) { 1 } else { 0 })
