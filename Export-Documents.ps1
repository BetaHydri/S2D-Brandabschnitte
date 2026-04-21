<#
.SYNOPSIS
    Exports the S2D documentation to DOCX and PDF with a table of contents
    and working internal glossary cross-references.

.DESCRIPTION
    Combines the three markdown documents (Brandabschnitte assessment,
    Setup guide, Glossar) into a single document, converts all cross-file
    links to internal anchors, and exports via pandoc to DOCX and PDF.

    Prerequisites:
    - pandoc (winget install JohnMacFarlane.Pandoc)
    - typst  (winget install Typst.Typst) — for PDF generation

.AUTHOR Jan Tiedemann

.DATE 2026

.EXAMPLE
    .\Export-Documents.ps1
    # Exports S2D-Brandabschnitte.docx and S2D-Brandabschnitte.pdf to docs/

.EXAMPLE
    .\Export-Documents.ps1 -Format docx
    # Exports only the DOCX file

.EXAMPLE
    .\Export-Documents.ps1 -Format pdf
    # Exports only the PDF file
#>
[CmdletBinding()]
param(
    [ValidateSet('all', 'docx', 'pdf')]
    [string]$Format = 'all',

    [string]$OutputDir = (Join-Path $PSScriptRoot 'docs')
)

$ErrorActionPreference = 'Stop'

# --- Verify prerequisites ---------------------------------------------------

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Source
if (-not $pandoc) {
    Write-Error 'pandoc not found. Install with: winget install JohnMacFarlane.Pandoc'
    return
}

if ($Format -in 'all', 'pdf') {
    $typst = Get-Command typst -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Source
    if (-not $typst) {
        Write-Error 'typst not found. Install with: winget install Typst.Typst'
        return
    }
}

# --- Read source files -------------------------------------------------------

$docsDir = Join-Path $PSScriptRoot 'docs'

$brandabschnitte = Get-Content (Join-Path $docsDir 's2d-brandabschnitte.md') -Raw -Encoding UTF8
$setupGuide      = Get-Content (Join-Path $docsDir 's2d-setup-guide.md')      -Raw -Encoding UTF8
$glossar         = Get-Content (Join-Path $docsDir 'glossar.md')              -Raw -Encoding UTF8

# --- Strip individual YAML front matter --------------------------------------

function Remove-YamlFrontMatter {
    param([string]$Content)
    # Match opening ---, any content, closing --- at start of file
    $Content -replace '(?s)\A---\r?\n.*?\r?\n---\r?\n', ''
}

$brandabschnitte = Remove-YamlFrontMatter $brandabschnitte
$setupGuide      = Remove-YamlFrontMatter $setupGuide
$glossar         = Remove-YamlFrontMatter $glossar

# --- Combined YAML front matter ----------------------------------------------

$culture = [System.Globalization.CultureInfo]::new('de-DE')
$today = (Get-Date).ToString('d. MMMM yyyy', $culture)
$frontMatter = @"
---
title: "Storage Spaces Direct über Brandabschnitte"
subtitle: "Technische Bewertung, Setup-Leitfaden und Glossar"
author: "Jan Tiedemann"
date: "$today"
lang: de
toc: true
toc-depth: 3
---
"@

# --- Combine documents -------------------------------------------------------

# Order: Assessment → Setup Guide → Glossar (reference at the end)
# \newpage markers are converted to page breaks by the Lua filter
$combined = @"
$frontMatter

$brandabschnitte

\newpage

$setupGuide

\newpage

$glossar
"@

# --- Convert cross-file links to internal anchors ----------------------------

# Links with anchors: (file.md#anchor) → (#anchor)
$combined = $combined -replace '\]\(glossar\.md#([^)]+)\)',              '](#$1)'
$combined = $combined -replace '\]\(s2d-brandabschnitte\.md#([^)]+)\)',  '](#$1)'
$combined = $combined -replace '\]\(s2d-setup-guide\.md#([^)]+)\)',      '](#$1)'

# Bare file links without anchors: point to first heading of each section
# Brandabschnitte first heading "# Zusammenfassung" → #zusammenfassung
# Setup Guide second "# Zusammenfassung" → #zusammenfassung-1 (pandoc deduplicates)
# Glossar heading "# Glossar — Fachbegriffe..." → #glossar--fachbegriffe-und-abkürzungen
$combined = $combined -replace '\]\(s2d-brandabschnitte\.md\)',  '](#zusammenfassung)'
$combined = $combined -replace '\]\(s2d-setup-guide\.md\)',      '](#zusammenfassung-1)'
$combined = $combined -replace '\]\(glossar\.md\)',              '](#glossar--fachbegriffe-und-abkürzungen)'

# --- Fix heading IDs: pandoc and GitHub generate different anchors -----------
# GitHub converts " / " → "--" (double hyphen), pandoc converts " / " → "-" (single)
# GitHub removes periods, pandoc may keep them. Add explicit {#id} attributes.
$combined = $combined -replace
    '(?m)(### Fault Domain / Fault Domain Awareness)\s*$',
    '$1 {#fault-domain--fault-domain-awareness}'
$combined = $combined -replace
    '(?m)(### Quorum / Cluster Quorum)\s*$',
    '$1 {#quorum--cluster-quorum}'
$combined = $combined -replace
    '(?m)(### Brandschott / Brandschottdurchführung)\s*$',
    '$1 {#brandschott--brandschottdurchführung}'
# Heading uses singular "Volume" but links use plural "Volumes"
$combined = $combined -replace
    '(?m)(### CSV \(Cluster Shared Volume\))\s*$',
    '$1 {#csv-cluster-shared-volumes}'
# Pandoc keeps the period in "vs." → "vs.-" but links expect "vs-"
$combined = $combined -replace
    '(?m)(## SET \(Switch Embedded Teaming\) vs\. NIC Teaming)\s*$',
    '$1 {#set-switch-embedded-teaming-vs-nic-teaming}'

# --- Create Lua filter for page breaks ---------------------------------------

$luaFilter = Join-Path $env:TEMP 's2d-pagebreak.lua'
@'
-- Page break filter: converts \newpage to native page breaks for docx and typst
function RawBlock(el)
  if el.format == "tex" or el.format == "latex" then
    if el.text:match("\\newpage") or el.text:match("\\pagebreak") then
      if FORMAT:match("docx") then
        return pandoc.RawBlock('openxml',
          '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
      elseif FORMAT:match("typst") then
        return pandoc.RawBlock('typst', '#pagebreak()')
      end
    end
  end
end

-- Keep code blocks together on one page (prevent mid-block page wraps)
function CodeBlock(el)
  if FORMAT:match("docx") then
    -- OOXML: wrap code block with keepLines + keepNext to prevent page split
    local escaped = el.text
      :gsub("&", "&amp;")
      :gsub("<", "&lt;")
      :gsub(">", "&gt;")
    local lines = {}
    for line in (escaped .. "\n"):gmatch("(.-)\n") do
      table.insert(lines, line)
    end
    local xml_parts = {}
    for i, line in ipairs(lines) do
      -- Use keepLines on every paragraph, keepNext on all but the last
      local keepNext = ""
      if i < #lines then
        keepNext = '<w:keepNext/>'
      end
      table.insert(xml_parts,
        '<w:p><w:pPr>'
        .. '<w:pStyle w:val="SourceCode"/>'
        .. '<w:keepLines/>' .. keepNext
        .. '</w:pPr><w:r><w:rPr>'
        .. '<w:rStyle w:val="VerbatimChar"/>'
        .. '</w:rPr><w:t xml:space="preserve">'
        .. line
        .. '</w:t></w:r></w:p>')
    end
    return pandoc.RawBlock('openxml', table.concat(xml_parts, "\n"))
  elseif FORMAT:match("typst") then
    -- Typst: wrap in a non-breakable block
    return {
      pandoc.RawBlock('typst', '#block(breakable: false)['),
      el,
      pandoc.RawBlock('typst', ']'),
    }
  end
end
'@ | Set-Content $luaFilter -Encoding UTF8

# --- Write combined markdown to temp file ------------------------------------

$tempMd = Join-Path $env:TEMP 's2d-combined.md'
# Use .NET to write without BOM (pandoc / typst can choke on BOM)
[System.IO.File]::WriteAllText($tempMd, $combined, [System.Text.UTF8Encoding]::new($false))

# --- Export -------------------------------------------------------------------

$baseName = 'S2D-Brandabschnitte'

if ($Format -in 'all', 'docx') {
    $docxPath = Join-Path $OutputDir "$baseName.docx"
    Write-Host "Exporting DOCX ..." -ForegroundColor Cyan

    & $pandoc $tempMd `
        -o $docxPath `
        --from markdown `
        --to docx `
        --toc `
        --toc-depth=3 `
        --lua-filter $luaFilter `
        --number-sections

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  DOCX: $docxPath" -ForegroundColor Green
    } else {
        Write-Warning "DOCX export failed (exit code $LASTEXITCODE)"
    }
}

if ($Format -in 'all', 'pdf') {
    $pdfPath = Join-Path $OutputDir "$baseName.pdf"
    Write-Host "Exporting PDF ..." -ForegroundColor Cyan

    # Create a typst header that styles links with visible blue color
    $typstHeader = Join-Path $env:TEMP 's2d-typst-header.typ'
    @'
// Make internal and external links visually distinguishable
#show link: it => {
  text(fill: rgb("#2563eb"), it)
}
'@ | Set-Content $typstHeader -Encoding UTF8

    & $pandoc $tempMd `
        -o $pdfPath `
        --from markdown `
        --pdf-engine=typst `
        --toc `
        --toc-depth=3 `
        --lua-filter $luaFilter `
        --number-sections `
        --include-in-header=$typstHeader

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  PDF:  $pdfPath" -ForegroundColor Green
    } else {
        Write-Warning "PDF export failed (exit code $LASTEXITCODE)"
    }
}

# --- Cleanup -----------------------------------------------------------------

Remove-Item $tempMd -Force -ErrorAction SilentlyContinue
Remove-Item $luaFilter -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:TEMP 's2d-typst-header.typ') -Force -ErrorAction SilentlyContinue

Write-Host "`nDone." -ForegroundColor Cyan