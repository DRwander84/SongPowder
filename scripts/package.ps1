<#
Builds SongPowder (Release) and produces, in dist\:
  SongPowder\                          portable folder (run SongPowder.exe, no Qt install needed)
  SongPowder-Portable-<ver>.zip        the same folder zipped
  SongPowder-Setup-<ver>.exe           Inno Setup installer

Usage (any PowerShell or cmd window, no special prompt needed):
  scripts\package.bat
  scripts\package.bat -QtDir C:\Qt\6.8.1\msvc2022_64 -InnoDir "D:\Programming\Inno Setup"

Options:
  -QtDir        Qt kit folder (the one that contains bin\windeployqt.exe). Auto-detected when omitted.
  -InnoDir      Inno Setup folder or full path of ISCC.exe. Default: D:\Programming\Inno Setup
  -RunTests     Build and run the unit tests before packaging (off by default)
  -SmokeTest    Start the packaged exe for a few seconds with Qt removed from PATH (portability check)
  -SkipInstaller / -SkipPortableZip   Build only part of the outputs
  -Clean        Delete the packaging build folder first
#>
param(
    [string]$QtDir = "",
    [string]$InnoDir = "D:\Programming\Inno Setup",
    [switch]$RunTests,
    [switch]$SmokeTest,
    [switch]$SkipInstaller,
    [switch]$SkipPortableZip,
    [switch]$Clean
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Fail($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function Run($exe, [string[]]$a) {
    & $exe @a
    if ($LASTEXITCODE -ne 0) { Fail "'$exe' failed with exit code $LASTEXITCODE" }
}

# ---------- version (single source of truth: CMakeLists.txt) ----------
$cml = Get-Content (Join-Path $root "CMakeLists.txt") -Raw
if ($cml -notmatch 'project\(\s*SongPowder\s+VERSION\s+([0-9]+(\.[0-9]+)*)') { Fail "Cannot read the version from CMakeLists.txt" }
$ver = $Matches[1]
Write-Host "SongPowder version $ver"

# ---------- Qt kit ----------
function Find-QtDir {
    if ($env:QT_DIR -and (Test-Path "$env:QT_DIR\bin\windeployqt.exe")) { return $env:QT_DIR }
    # reuse the kit of an existing build folder (e.g. the one Qt Creator / a previous build used)
    foreach ($cache in (Get-ChildItem -Path (Join-Path $root "build*") -Filter CMakeCache.txt -Recurse -Depth 2 -ErrorAction SilentlyContinue)) {
        $line = Select-String -Path $cache.FullName -Pattern '^CMAKE_PREFIX_PATH:[A-Z]+=(.+)$' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($line) {
            foreach ($p in ($line.Matches[0].Groups[1].Value -split ';')) {
                if ($p -and (Test-Path "$p\bin\windeployqt.exe")) { return $p }
            }
        }
    }
    $cands = @()
    foreach ($base in @("C:\Qt", "D:\Qt", "D:\Programming\Qt", "E:\Qt")) {
        if (Test-Path $base) {
            $cands += Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^6\.\d+' } | ForEach-Object {
                    $v = $_
                    Get-ChildItem -Path $v.FullName -Directory -Filter "msvc*_64" -ErrorAction SilentlyContinue |
                        ForEach-Object { [pscustomobject]@{ Ver = [version]($v.Name -replace '^(\d+\.\d+(\.\d+)?).*', '$1'); Path = $_.FullName } }
                }
        }
    }
    $best = $cands | Sort-Object Ver -Descending | Select-Object -First 1
    if ($best) { return $best.Path }
    return ""
}
if (-not $QtDir) { $QtDir = Find-QtDir }
if (-not $QtDir) { Fail "Qt kit not found. Pass it explicitly: scripts\package.bat -QtDir C:\Qt\6.8.1\msvc2022_64" }
$QtDir = (Resolve-Path $QtDir).Path.TrimEnd('\')
$deployTool = Join-Path $QtDir "bin\windeployqt.exe"
if (-not (Test-Path $deployTool)) { Fail "windeployqt.exe not found in '$QtDir\bin'. QtDir must be the MSVC kit folder (e.g. C:\Qt\6.8.1\msvc2022_64)." }
if (-not (Test-Path "$QtDir\lib\cmake\Qt6")) { Fail "'$QtDir' is not a Qt 6 kit (lib\cmake\Qt6 missing)." }
Write-Host "Qt kit: $QtDir"

# ---------- MSVC environment (so the script works from a normal PowerShell too) ----------
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Step "Loading the Visual Studio 2022 x64 build environment"
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { Fail "Visual Studio not found (vswhere.exe missing). Install VS 2022 with 'Desktop development with C++'." }
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { Fail "Visual Studio C++ tools not found." }
    $vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
    if (-not (Test-Path $vcvars)) { Fail "vcvars64.bat not found: $vcvars" }
    $envDump = & cmd.exe /c "`"$vcvars`" >nul 2>&1 && set"
    foreach ($l in $envDump) {
        if ($l -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], "Process") }
    }
    if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) { Fail "cl.exe still not available after loading vcvars64.bat." }
}
# cmake / ninja: VS ships both; fall back to the copies in the Qt installation (Qt\Tools)
$qtTools = Join-Path (Split-Path (Split-Path $QtDir -Parent) -Parent) "Tools"
foreach ($t in @(@{n="cmake.exe"; sub="CMake_64\bin"}, @{n="ninja.exe"; sub="Ninja"})) {
    if (-not (Get-Command $t.n -ErrorAction SilentlyContinue)) {
        $dir = Join-Path $qtTools $t.sub
        if (Test-Path (Join-Path $dir $t.n)) { $env:PATH = "$dir;$env:PATH" }
        else { Fail "$($t.n) not found (neither on PATH nor in $dir)." }
    }
}

# ---------- Inno Setup ----------
$iscc = ""
if (-not $SkipInstaller) {
    $tries = @()
    if ($InnoDir) { $tries += $InnoDir; $tries += (Join-Path $InnoDir "ISCC.exe") }
    $tries += "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
              "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    foreach ($t in $tries) {
        if ($t -and (Test-Path $t -PathType Leaf) -and ($t -like "*ISCC.exe")) { $iscc = $t; break }
    }
    if (-not $iscc) {
        $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if ($cmd) { $iscc = $cmd.Source }
    }
    if (-not $iscc) { Fail "ISCC.exe not found. Looked in '$InnoDir' and the default Inno Setup 6 folders. Use -InnoDir <folder or ISCC.exe path>, or -SkipInstaller." }
    Write-Host "Inno Setup: $iscc"
}

# ---------- build ----------
$bd = Join-Path $root "build\package"
if ($Clean -and (Test-Path $bd)) { Step "Cleaning $bd"; Remove-Item $bd -Recurse -Force }
Step "Configuring (Release, Ninja)"
# SP_AUTO_DEPLOY=OFF: this script deploys Qt itself, so the post-build windeployqt step is not needed
Run "cmake" @("-S", $root, "-B", $bd, "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_PREFIX_PATH=$QtDir", "-DSP_AUTO_DEPLOY=OFF")
Step "Building"
Run "cmake" @("--build", $bd)
$exe = Join-Path $bd "SongPowder.exe"
if (-not (Test-Path $exe)) { Fail "Build finished but SongPowder.exe was not produced at $exe" }

if ($RunTests) {
    Step "Running unit tests"
    $oldPath = $env:PATH; $oldQpa = $env:QT_QPA_PLATFORM
    $env:PATH = "$QtDir\bin;$env:PATH"; $env:QT_QPA_PLATFORM = "offscreen"
    try { Run "ctest" @("--test-dir", $bd, "--output-on-failure") }
    finally { $env:PATH = $oldPath; $env:QT_QPA_PLATFORM = $oldQpa }
}

# ---------- portable folder ----------
$distRoot = Join-Path $root "dist"
$dist = Join-Path $distRoot "SongPowder"
Step "Creating the portable folder: $dist"
New-Item -ItemType Directory -Force $distRoot | Out-Null
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force $dist | Out-Null
Copy-Item $exe $dist
Run $deployTool @("--release", "--qmldir", (Join-Path $root "qml"), "--compiler-runtime",
                  "--no-translations", "--no-system-d3d-compiler", "--no-opengl-sw", (Join-Path $dist "SongPowder.exe"))

# Trim what windeployqt adds but SongPowder never uses (smaller package, and no unresolved DLLs from unused SQL drivers)
$vcInstaller = Join-Path $dist "vc_redist.x64.exe"            # the runtime DLLs are copied below instead
if (Test-Path $vcInstaller) { Remove-Item $vcInstaller -Force }
$dbg = Join-Path $dist "qmltooling"                           # QML debugger plugins
if (Test-Path $dbg) { Remove-Item $dbg -Recurse -Force }
Get-ChildItem -Path (Join-Path $dist "sqldrivers") -Filter *.dll -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "qsqlite.dll" } | Remove-Item -Force   # only SQLite is used

# MSVC runtime: make sure it is really there (the target PC may not have the VC++ Redistributable)
foreach ($dll in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll")) {
    if (-not (Test-Path (Join-Path $dist $dll))) {
        $src = $null
        if ($env:VCToolsRedistDir) {
            $src = Get-ChildItem -Path (Join-Path $env:VCToolsRedistDir "x64") -Filter $dll -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($src) { Copy-Item $src.FullName $dist; Write-Host "  added $dll from the VS redistributable folder" }
        else { Write-Warning "$dll is not in the package; PCs without the VC++ 2015-2022 Redistributable may not start the app." }
    }
}

Copy-Item (Join-Path $root "LICENSE") (Join-Path $dist "LICENSE.txt")
if (Test-Path (Join-Path $root "NOTICE")) { Copy-Item (Join-Path $root "NOTICE") (Join-Path $dist "NOTICE.txt") }
@"
SongPowder is released under the Apache License 2.0 (LICENSE.txt). Attribution and change notices: NOTICE.txt.

This package includes Qt $((Split-Path $QtDir -Parent | Split-Path -Leaf)) libraries, used under the GNU LGPL v3 and linked dynamically
(the Qt*.dll files and plugin folders next to SongPowder.exe can be replaced by your own build of the same Qt version).
Qt source code and license texts: https://www.qt.io/licensing/ and https://download.qt.io/
The Qt Multimedia FFmpeg backend bundles FFmpeg (LGPL): https://ffmpeg.org/legal.html
"@ | Set-Content -Path (Join-Path $dist "THIRD-PARTY-NOTICES.txt") -Encoding UTF8

# ---------- verify the folder is self-contained ----------
Step "Verifying the portable folder"
$must = @("SongPowder.exe", "Qt6Core.dll", "Qt6Gui.dll", "Qt6Qml.dll", "Qt6Quick.dll", "Qt6QuickControls2.dll", "Qt6Multimedia.dll",
          "Qt6Sql.dll", "platforms\qwindows.dll", "sqldrivers\qsqlite.dll", "imageformats\qjpeg.dll",
          "qml\QtQuick\Controls\qtquickcontrols2plugin.dll", "qml\QtQuick\Dialogs", "qml\QtQuick\Effects", "qml\QtQuick\Layouts",
          "qml\QtQuick\Controls\Basic")
$missing = @($must | Where-Object { -not (Test-Path (Join-Path $dist $_)) })
if (-not (Get-ChildItem -Path (Join-Path $dist "multimedia") -Filter *.dll -ErrorAction SilentlyContinue)) { $missing += "multimedia\*.dll (Qt Multimedia backend plugin)" }
if ($missing.Count -gt 0) { Fail ("The package is incomplete, missing:`n  " + ($missing -join "`n  ")) }

# every DLL the exe, Qt libraries and plugins import must be inside the folder or be a Windows system DLL
$dumpbin = Get-Command dumpbin.exe -ErrorAction SilentlyContinue
if ($dumpbin) {
    $sys32 = Join-Path $env:windir "System32"
    $have = @{}
    Get-ChildItem -Path $dist -Filter *.dll -Recurse | ForEach-Object { $have[$_.Name.ToLower()] = $true }
    $unresolved = @{}
    foreach ($f in (Get-ChildItem -Path $dist -Recurse -Include *.dll, *.exe)) {
        foreach ($l in (& dumpbin.exe /nologo /dependents $f.FullName)) {
            if ($l -match '^\s+(\S+\.dll)\s*$') {
                $n = $Matches[1].ToLower()
                if ($n -like "api-ms-win-*" -or $have.ContainsKey($n) -or (Test-Path (Join-Path $sys32 $n))) { continue }
                $unresolved[$n] = $f.Name
            }
        }
    }
    if ($unresolved.Count -gt 0) {
        Fail ("These DLLs are imported but neither packaged nor part of Windows:`n  " + (($unresolved.GetEnumerator() | ForEach-Object { "$($_.Key)  (needed by $($_.Value))" }) -join "`n  "))
    }
    Write-Host "  all imported DLLs are present: OK"
} else {
    Write-Warning "dumpbin.exe not available: skipped the DLL dependency check."
}

if ($SmokeTest) {
    Step "Smoke test: starting the packaged exe with Qt removed from PATH"
    $oldPath = $env:PATH
    $env:PATH = "$env:windir\System32;$env:windir"
    foreach ($v in @("QT_PLUGIN_PATH", "QML_IMPORT_PATH", "QML2_IMPORT_PATH", "QT_QPA_PLATFORM_PLUGIN_PATH", "QT_DIR")) { Remove-Item "env:$v" -ErrorAction SilentlyContinue }
    try {
        $p = Start-Process -FilePath (Join-Path $dist "SongPowder.exe") -PassThru
        Start-Sleep -Seconds 8
        if ($p.HasExited) { Fail "SongPowder.exe exited early (code $($p.ExitCode)). See %LOCALAPPDATA%\SongPowder\logs\songpowder.log" }
        Write-Host "  still running after 8 s. Check on screen that the window opened normally (an error box would also keep it alive)."
        Stop-Process -Id $p.Id -Force
    } finally { $env:PATH = $oldPath }
}

# ---------- portable zip ----------
$zip = Join-Path $distRoot "SongPowder-Portable-$ver.zip"
if (-not $SkipPortableZip) {
    Step "Creating $zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dist, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $true)
}

# ---------- installer ----------
$setup = Join-Path $distRoot "SongPowder-Setup-$ver.exe"
if (-not $SkipInstaller) {
    Step "Compiling the installer"
    if (Test-Path $setup) { Remove-Item $setup -Force }
    Run $iscc @("/Qp", "/DAppVersion=$ver", "/DBuildOutput=$dist", "/O$distRoot", (Join-Path $root "installer\SongPowder.iss"))
    if (-not (Test-Path $setup)) { Fail "ISCC finished but $setup was not created." }
}

Step "Done"
Write-Host "Portable folder : $dist"
if (-not $SkipPortableZip) { Write-Host "Portable zip    : $zip" }
if (-not $SkipInstaller)   { Write-Host "Installer       : $setup" }
