[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [string]$SptPath = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
[xml]$props = Get-Content -LiteralPath (Join-Path $repoRoot 'Directory.Build.props')

if ([string]::IsNullOrWhiteSpace($SptPath)) {
    $SptPath = [string]$props.Project.PropertyGroup.SPTPath
}

$modVersion = [string]$props.Project.PropertyGroup.ModVersion
$packagePath = Join-Path $repoRoot "Manimal-HarryHead-$modVersion.zip"

$sptRoot = [System.IO.Path]::GetFullPath($SptPath)
$modsRoot = Join-Path $sptRoot 'SPT\user\mods'
if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) {
    throw "SPT mods directory was not found: $modsRoot"
}

$project = Join-Path $repoRoot 'HarryHeadServer\HarryHeadServer.csproj'
$serverFiles = Join-Path $repoRoot 'ServerModFiles'
$deployDir = Join-Path $modsRoot 'HarryHeadServer'

Write-Host "Building and packaging HarryHeadServer ($Configuration)..." -ForegroundColor Cyan
dotnet build $project -c $Configuration -t:PackageModForDistribution -p:SkipDeploy=true
if ($LASTEXITCODE -ne 0) {
    throw "HarryHeadServer build/package failed with exit code $LASTEXITCODE"
}

$builtDll = Join-Path $repoRoot "HarryHeadServer\bin\$Configuration\HarryHeadServer.dll"
if (-not (Test-Path -LiteralPath $builtDll -PathType Leaf)) {
    throw "Build succeeded, but the server DLL was not found: $builtDll"
}

if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
    throw "Build succeeded, but the release package was not found: $packagePath"
}

$bundleManifestPath = Join-Path $serverFiles 'bundles.json'
$bundleManifest = Get-Content -LiteralPath $bundleManifestPath -Raw | ConvertFrom-Json
foreach ($entry in $bundleManifest.manifest) {
    $bundlePath = Join-Path (Join-Path $serverFiles 'bundles') ([string]$entry.key)
    if (-not (Test-Path -LiteralPath $bundlePath -PathType Leaf)) {
        Write-Warning "Manifest bundle not found at $bundlePath. The ZIP will still be created, but that asset cannot load."
    }
}

New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
Copy-Item -LiteralPath $builtDll -Destination $deployDir -Force
Copy-Item -Path (Join-Path $serverFiles '*') -Destination $deployDir -Recurse -Force

Write-Host "Deployed HarryHeadServer to $deployDir" -ForegroundColor Green
Write-Host "Packaged release at $packagePath" -ForegroundColor Green
