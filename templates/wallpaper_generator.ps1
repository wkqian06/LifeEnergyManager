# LifeEnergyManager wallpaper generator (Windows PowerShell 5.1+)
# Thin orchestration entry point. Rendering logic lives in wallpaper_renderer.psm1.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File templates\wallpaper_generator.ps1 -ConfigPath <config.json>

param([Parameter(Mandatory=$true)][string]$ConfigPath)

$ErrorActionPreference = 'Stop'
$rendererModule = Join-Path $PSScriptRoot 'wallpaper_renderer.psm1'
Import-Module $rendererModule -Force

$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
Invoke-LifeEnergyWallpaperRender -Config $config
