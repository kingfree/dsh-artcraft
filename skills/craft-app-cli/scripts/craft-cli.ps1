#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Find and drive the headless "<app>-cli" tools that ship with the Craft apps.

.DESCRIPTION
  Every Craft app exposes the same commands its window runs through a <app>-cli
  binary that needs no GUI (wordcraft-cli, gridcraft-cli, photocraft-cli, ...).
  This helper only locates those binaries and hands arguments to them; it never
  parses, converts or renders files itself.

  Actions:
    list                     Every known app, its CLI and whether it is installed.
    find <app>               Print the resolved CLI path (exit 1 when missing).
    route <file>             Guess the app from the extension and print ready commands.
    formats                  Extension -> app routing table.
    <app> <args...>          Run that app's CLI with the given arguments (pass-through).

  Add extra install roots with CRAFT_CLI_DIRS (semicolon-separated on Windows,
  colon-separated elsewhere).

.EXAMPLES
  ./craft-cli.ps1 list
  ./craft-cli.ps1 find wordcraft
  ./craft-cli.ps1 route .\report.docx
  ./craft-cli.ps1 wordcraft text .\report.docx
  ./craft-cli.ps1 gridcraft convert .\book.xlsx .\book.csv
  ./craft-cli.ps1 pdfcraft render .\scan.pdf --page 1 --dpi 150 --out .\page1.png
  ./craft-cli.ps1 wordcraft mcp          # start the MCP server for an AI assistant
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action = 'list',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Rest = @()
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# App table.
#   App      - command-line slug (aliases also accepted)
#   Display  - install folder / human name
#   Cli      - headless binary base name
#   Formats  - extensions routed to this app (lower case, with dot)
#   Quick    - ready-made commands shown by `route`; {file} and {stem} are replaced
#   Aliases  - extra names accepted by find / pass-through
# ---------------------------------------------------------------------------
$CraftApps = @(
    [pscustomobject]@{
        App = 'photocraft'; Display = 'PhotoCraft'; Cli = 'photocraft-cli'
        Formats = @('.pcraft', '.psd', '.psb', '.ora', '.xcf', '.kra', '.krz', '.pdn', '.afphoto', '.tif', '.tiff', '.png', '.jpg', '.jpeg', '.webp', '.exr', '.gif', '.bmp', '.heic', '.heif', '.jxl', '.hdr', '.tga', '.dds', '.dpx', '.cin', '.fits', '.pnm')
        Quick = @('info "{file}"', 'convert "{file}" "{stem}.png"', 'commands')
        Aliases = @('photo', 'ps', 'photoshop')
    }
    [pscustomobject]@{
        App = 'vectorcraft'; Display = 'VectorCraft'; Cli = 'vectorcraft-cli'
        Formats = @('.ai', '.ait', '.svg', '.svgz', '.eps', '.epsf', '.ps', '.afdesign', '.afpub', '.vctemplate', '.emf', '.wmf')
        Quick = @('convert "{file}" "{stem}.svg"', 'convert "{file}" "{stem}.png"', 'commands')
        Aliases = @('vector', 'ai', 'illustrator')
    }
    [pscustomobject]@{
        App = 'lightcraft'; Display = 'LightCraft'; Cli = 'lightcraft-cli'
        Formats = @('.dng', '.cr2', '.cr3', '.nef', '.arw', '.raf', '.orf', '.rw2', '.rwl', '.pef', '.raw', '.fff', '.lrcat')
        Quick = @('render "{file}" -o "{stem}.jpg"', 'run --import "{file}" app.export path="{stem}.jpg"')
        Aliases = @('light', 'lightroom', 'raw')
    }
    [pscustomobject]@{
        App = 'designcraft'; Display = 'DesignCraft'; Cli = 'designcraft-cli'
        Formats = @('.designcraft', '.indd', '.indt', '.idml')
        Quick = @('run --in "{file}" --export "{stem}.pdf"', 'run --in "{file}" --export "{stem}.idml"', 'run --in "{file}" --all-pages "{stem}-pages"')
        Aliases = @('design', 'id', 'indesign')
    }
    [pscustomobject]@{
        App = 'figcraft'; Display = 'FigCraft'; Cli = 'figcraft-cli'
        Formats = @('.figcraft', '.fig', '.sketch', '.penpot', '.jam')
        Quick = @('info "{file}"', 'export --out "{stem}" "{file}"', 'convert "{file}" "{stem}.svg"', 'render --out "{stem}.png" "{file}"')
        Aliases = @('fig', 'figma')
    }
    [pscustomobject]@{
        App = 'texturecraft'; Display = 'TextureCraft'; Cli = 'texturecraft-cli'
        Formats = @('.tcraft', '.glb', '.gltf', '.fbx', '.dae', '.abc', '.ply', '.usd', '.usda', '.usdc', '.usdz')
        Quick = @('info "{file}"', 'export "{file}" "{stem}-textures"', 'render "{file}" "{stem}.png"')
        Aliases = @('texture', 'substance-painter', 'painter')
    }
    [pscustomobject]@{
        App = 'materialcraft'; Display = 'MaterialCraft'; Cli = 'materialcraft-cli'
        Formats = @('.sbs', '.sbsar', '.mcraft', '.mcmat')
        Quick = @('info "{file}"', 'export "{file}" "{stem}-maps"', 'render "{file}" "{stem}.png"', 'cook "{file}"')
        Aliases = @('material', 'substance-designer', 'designer')
    }
    [pscustomobject]@{
        App = 'filmcraft'; Display = 'FilmCraft'; Cli = 'filmcraft-cli'
        Formats = @('.fcproj', '.mp4', '.mov', '.mxf', '.m4v', '.avi', '.mkv', '.webm', '.mts', '.m2ts', '.ts', '.fcpxml', '.otio', '.edl', '.aaf', '.omf')
        Quick = @('probe "{file}"', 'inspect', 'render --seconds 1 --out "{stem}.png"')
        Aliases = @('film', 'pr', 'premiere')
    }
    [pscustomobject]@{
        App = 'effectcraft'; Display = 'EffectCraft'; Cli = 'effectcraft-cli'
        Formats = @('.ecproj', '.ectemplate', '.aep', '.aepx')
        Quick = @('info', 'render-frame --time 1 --out "{stem}.png"', 'commands')
        Aliases = @('effect', 'ae', 'aftereffects')
    }
    [pscustomobject]@{
        App = 'soundcraft'; Display = 'SoundCraft'; Cli = 'soundcraft-cli'
        Formats = @('.scraft', '.wav', '.wave', '.bwf', '.rf64', '.aif', '.aiff', '.aifc', '.flac', '.mp3', '.mp2', '.ogg', '.oga', '.m4a', '.m4b', '.aac', '.caf', '.alac', '.mid', '.midi')
        Quick = @('info "{file}"', 'convert "{file}" "{stem}.wav"', 'commands')
        Aliases = @('sound', 'audio', 'audition')
    }
    [pscustomobject]@{
        App = 'cadcraft'; Display = 'CADCraft'; Cli = 'cadcraft-cli'
        Formats = @('.dwg', '.dxf', '.dwt', '.dws', '.scr', '.lsp')
        Quick = @('info "{file}"', 'convert "{file}" "{stem}.svg"', 'convert "{file}" "{stem}.pdf"', 'commands')
        Aliases = @('cad', 'dwg', 'autocad')
    }
    [pscustomobject]@{
        App = 'wordcraft'; Display = 'WordCraft'; Cli = 'wordcraft-cli'
        Formats = @('.docx', '.doc', '.rtf', '.odt', '.txt', '.tex', '.html', '.htm', '.md')
        Quick = @('text "{file}"', 'info "{file}"', 'convert "{file}" "{stem}.md"', 'convert "{file}" "{stem}.pdf"', 'render "{file}" "{stem}.png"')
        Aliases = @('word', 'docx', 'doc', 'writer')
    }
    [pscustomobject]@{
        App = 'gridcraft'; Display = 'GridCraft'; Cli = 'gridcraft-cli'
        Formats = @('.xlsx', '.xlsm', '.xls', '.xlsb', '.ods', '.csv', '.tsv')
        Quick = @('info "{file}" --json', 'cat "{file}" --csv', 'convert "{file}" "{stem}.csv"', 'convert "{file}" "{stem}.pdf"')
        Aliases = @('grid', 'xlsx', 'excel', 'sheet')
    }
    [pscustomobject]@{
        App = 'deckcraft'; Display = 'DeckCraft'; Cli = 'deckcraft-cli'
        Formats = @('.deckcraft', '.pptx', '.pptm', '.potx', '.ppsx')
        Quick = @('info "{file}"', 'render "{file}" --all "{stem}-slides"', 'convert "{file}" "{stem}.pdf"', 'convert "{file}" "{stem}.md"')
        Aliases = @('deck', 'pptx', 'ppt', 'powerpoint', 'slides')
    }
    [pscustomobject]@{
        App = 'pdfcraft'; Display = 'PdfCraft'; Cli = 'pdfcraft-cli'
        Formats = @('.pdf')
        Quick = @('info "{file}"', 'text "{file}"', 'render "{file}" --page 1 --dpi 150 --out "{stem}-p1.png"', 'extract "{file}" --pages 1 --out "{stem}-p1.pdf"')
        Aliases = @('pdf', 'acrobat')
    }
    [pscustomobject]@{
        App = 'solidcraft'; Display = 'SolidCraft'; Cli = 'solidcraft-cli'
        Formats = @('.sc', '.step', '.stp', '.iges', '.igs', '.3mf', '.stl', '.obj')
        Quick = @('eval "{file}" --json-out "{stem}.json"', 'script "{file}" --out "{stem}.json"', 'snapshot --in "{file}" --out "{stem}.png"', 'run --in "{file}" --out "{stem}.step"')
        Aliases = @('solid', 'step', 'stp')
    }
    [pscustomobject]@{
        App = 'craft-anything'; Display = 'Craft Anything'; Cli = 'craft-anything-cli'
        Formats = @('.cany')
        Quick = @('triage "{file}"', 'report')
        Aliases = @('anything', 'explore')
    }
    [pscustomobject]@{
        App = 'artcraft-studio'; Display = 'ArtCraft Studio'; Cli = 'artcraft-studio-cli'
        Formats = @()
        Quick = @()
        Aliases = @('artcraft', 'studio', 'artcraftstudio')
        NoCliDocumented = $true
    }
)

# Formats that no Craft app can open (say so instead of guessing).
$UnsupportedFormats = @{
    '.prproj'  = 'FilmCraft cannot open Premiere .prproj yet. Export FCPXML / AAF / OTIO from Premiere, then use filmcraft-cli import.'
    '.indb'    = 'DesignCraft cannot open InDesign books.'
    '.indl'    = 'DesignCraft cannot open InDesign libraries.'
    '.key'     = 'No Craft app reads Keynote files.'
    '.pages'   = 'No Craft app reads Pages files.'
    '.numbers' = 'No Craft app reads Numbers files.'
}

# ---------------------------------------------------------------------------
# Locating the binaries
# ---------------------------------------------------------------------------
function Test-CliFile {
    param([string]$Path)
    return ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf))
}

function Get-CliSearchRoots {
    param([pscustomobject]$App)

    $roots = [System.Collections.Generic.List[string]]::new()
    $isWin = $IsWindows -or $env:OS -eq 'Windows_NT'

    if ($env:CRAFT_CLI_DIRS) {
        $sep = if ($isWin) { ';' } else { ':' }
        foreach ($d in $env:CRAFT_CLI_DIRS.Split($sep)) {
            if ($d.Trim()) { $roots.Add($d.Trim()) }
        }
    }

    if ($isWin) {
        foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
            if (-not $base) { continue }
            $roots.Add((Join-Path $base $App.Display))                    # C:\Program Files\<App>
            $roots.Add((Join-Path $base "Programs\$($App.Display)"))       # %LOCALAPPDATA%\Programs\<App>
            $roots.Add((Join-Path $base "ArtCraft\$($App.Display)"))       # per-machine ArtCraft install
            $roots.Add((Join-Path $base "Programs\ArtCraft\$($App.Display)"))
        }
    }
    elseif ($IsMacOS) {
        $roots.Add("/Applications/$($App.Display).app/Contents/MacOS")
        $roots.Add("/Applications/ArtCraft/$($App.Display).app/Contents/MacOS")
        $roots.Add('/usr/local/bin')
        $roots.Add('/opt/homebrew/bin')
    }
    else {
        $roots.Add('/usr/bin')
        $roots.Add('/usr/local/bin')
        $roots.Add("/opt/$($App.App)")
        $roots.Add((Join-Path $HOME '.local/bin'))
    }
    if ($App.Display -eq 'SolidCraft' -and $isWin) { $roots.Add('C:\Program Files\SolidCraft') }
    $roots.Add((Get-Location).Path)
    return $roots
}

function Resolve-CraftCli {
    param(
        [pscustomobject]$App,
        [switch]$Deep
    )

    if ($App.NoCliDocumented) { return $null }

    $cli = $App.Cli
    $candidates = [System.Collections.Generic.List[string]]::new()

    # 1. On PATH (a portable install the user added themselves).
    $onPath = Get-Command $cli -ErrorAction SilentlyContinue
    if ($onPath -and $onPath.Source) { $candidates.Add($onPath.Source) }

    # 2. Known install folders.
    foreach ($root in Get-CliSearchRoots -App $App) {
        if (-not $root) { continue }
        foreach ($name in @($cli, "$cli.exe")) {
            $p = Join-Path $root $name
            if (Test-CliFile $p) { $candidates.Add($p) }
        }
    }

    # 3. Broad scan of Program Files (opt-in), for unusual layouts.
    if ($Deep -and -not ($candidates | Where-Object { Test-CliFile $_ })) {
        $isWin = $IsWindows -or $env:OS -eq 'Windows_NT'
        if ($isWin) {
            foreach ($base in @($env:ProgramFiles, "$env:LOCALAPPDATA\Programs")) {
                if (-not $base -or -not (Test-Path $base)) { continue }
                Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like '*Craft*' } |
                    ForEach-Object {
                        foreach ($name in @($cli, "$cli.exe")) {
                            $p = Join-Path $_.FullName $name
                            if (Test-CliFile $p) { $candidates.Add($p) }
                        }
                    }
            }
        }
    }

    return ($candidates | Where-Object { Test-CliFile $_ } | Select-Object -First 1)
}

function Resolve-App {
    param([string]$Name)
    $key = $Name.ToLowerInvariant() -replace '\.exe$', ''
    foreach ($a in $CraftApps) {
        if ($key -eq $a.App -or $key -eq ($a.Cli -replace '-cli$', '')) { return $a }
        if ($key -eq $a.Display.ToLowerInvariant()) { return $a }
        if ($a.Aliases -contains $key) { return $a }
    }
    return $null
}

function Format-InstallHint {
    param([pscustomobject]$App)
    $url = "https://craft.wiki/apps/$($App.App)/install-update/"
    if ($App.NoCliDocumented) {
        return "$($App.Display) has no documented headless CLI; it is a GUI/cloud app. See https://craft.wiki/apps/$($App.App)/overview/"
    }
    $win = "%ProgramFiles%\$($App.Display)\$($App.Cli).exe"
    return "Install $($App.Display) so $($App.Cli) exists (Windows: $win; also %LOCALAPPDATA%\Programs\ArtCraft\$($App.Display)\; macOS/Linux: alongside the app, see $url), or set CRAFT_CLI_DIRS to its folder. Docs: $url"
}

function Write-Err([string]$Text) { [Console]::Error.WriteLine($Text) }

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
function Show-List {
    $rows = foreach ($a in $CraftApps) {
        $p = Resolve-CraftCli -App $a
        [pscustomobject]@{
            App    = $a.App
            Cli    = if ($a.NoCliDocumented) { '(no CLI)' } else { $a.Cli }
            Status = if ($a.NoCliDocumented) { 'no-cli' } elseif ($p) { 'installed' } else { 'missing' }
            Path   = if ($p) { $p } else { '' }
        }
    }
    $rows | Format-Table -AutoSize | Out-String -Width 4096 | Write-Output
    $missing = @($rows | Where-Object Status -eq 'missing')
    $noclis = @($rows | Where-Object Status -eq 'no-cli')
    Write-Output ("{0} installed / {1} missing / {2} without CLI" -f ($rows.Count - $missing.Count - $noclis.Count), $missing.Count, $noclis.Count)
    if ($missing.Count -gt 0) {
        Write-Output "Missing CLIs: run `"$($MyInvocation.MyCommand.Name) find <app>`" for the expected path and install page."
    }
}

function Show-Find {
    param([string]$Name)
    if (-not $Name) { Write-Err 'find needs an app name'; exit 2 }
    $app = Resolve-App $Name
    if (-not $app) { Write-Err "unknown app '$Name'. Run `"$($MyInvocation.MyCommand.Name) list`"."; exit 2 }
    $p = Resolve-CraftCli -App $app -Deep
    if ($p) { Write-Output $p; exit 0 }
    Write-Err (Format-InstallHint $app)
    exit 1
}

function Show-Formats {
    $rows = foreach ($a in $CraftApps) {
        foreach ($f in $a.Formats) {
            [pscustomobject]@{ Extension = $f; App = $a.App; Cli = $a.Cli }
        }
    }
    $rows | Sort-Object Extension | Format-Table -AutoSize | Out-String -Width 4096 | Write-Output
}

function Show-Route {
    param([string]$File)
    if (-not $File) { Write-Err 'route needs a file path'; exit 2 }
    $ext = [System.IO.Path]::GetExtension($File).ToLowerInvariant()
    $name = [System.IO.Path]::GetFileName($File)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($File)

    if ($UnsupportedFormats.ContainsKey($ext)) {
        Write-Output "No Craft app handles '$ext'."
        Write-Output $UnsupportedFormats[$ext]
        exit 3
    }

    $app = $CraftApps | Where-Object { $_.Formats -contains $ext } | Select-Object -First 1

    if (-not $app) {
        Write-Output "No Craft app claims '$ext'."
        $ca = Resolve-App 'craft-anything'
        $caPath = if ($ca) { Resolve-CraftCli -App $ca } else { $null }
        if ($caPath) {
            Write-Output "General first look (Craft Anything):"
            Write-Output "  `"$caPath`" triage `"$name`""
        }
        Write-Output "App list: https://craft.wiki/#apps"
        exit 3
    }

    $exists = Test-Path -LiteralPath $File
    $p = Resolve-CraftCli -App $app
    Write-Output "file : $name$(if ($exists) { " ($((Get-Item -LiteralPath $File).Length) bytes)" } else { ' (not found on disk)' })"
    Write-Output "app  : $($app.Display)  ->  $($app.Cli)"
    if ($p) {
        Write-Output "cli  : $p"
    }
    else {
        Write-Output "cli  : NOT INSTALLED. $(Format-InstallHint $app)"
    }
    if ($app.Quick -and $app.Quick.Count -gt 0) {
        Write-Output ''
        Write-Output 'Ready commands (replace the CLI path with ".\craft-cli.ps1 <app>" to auto-locate it):'
        foreach ($q in $app.Quick) {
            $cmd = $q.Replace('{file}', $name).Replace('{stem}', $stem)
            Write-Output "  $($app.Cli) $cmd"
        }
    }
    exit 0
}

function Invoke-PassThrough {
    param([string]$Name, [string[]]$Arguments)
    $app = Resolve-App $Name
    if (-not $app) { Write-Err "unknown app '$Name'. Run `"$($MyInvocation.MyCommand.Name) list`"."; exit 2 }
    $p = Resolve-CraftCli -App $app -Deep
    if (-not $p) { Write-Err (Format-InstallHint $app); exit 1 }
    Write-Verbose "exec: $p $($Arguments -join ' ')"
    & $p @Arguments
    exit $LASTEXITCODE
}

switch ($Action.ToLowerInvariant()) {
    'list'    { Show-List }
    'status'  { Show-List }
    'formats' { Show-Formats }
    'find'    { Show-Find -Name ($Rest | Select-Object -First 1) }
    'route'   { Show-Route -File ($Rest | Select-Object -First 1) }
    'help'    { Get-Help $PSCommandPath -Detailed; exit 0 }
    '--help'  { Get-Help $PSCommandPath -Detailed; exit 0 }
    '-h'      { Get-Help $PSCommandPath -Detailed; exit 0 }
    default   { Invoke-PassThrough -Name $Action -Arguments $Rest }
}
