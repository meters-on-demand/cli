function Test-BuiltIn {
    param(
        [Parameter(Mandatory)]
        [string]
        $Plugin
    )

    $Cache = $MetersOnDemand.Cache
    $RainmeterDirectory = $Cache.RainmeterDirectory

    $builtInPlugins = Get-ChildItem -Path "$($RainmeterDirectory)\Plugins\*"

    foreach ($p in $builtInPlugins) {
        if ($p.BaseName -match "$($Plugin)") {
            return $True
        }
    }

    return $False

}

function Get-LatestPlugin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Plugin,
        [Parameter()]
        [switch]
        $Quiet
    )

    $Cache = $MetersOnDemand.Cache
    $SkinPath = $Cache.SkinPath

    $vault = "$($SkinPath)\@Vault"
    if (!(Test-Path $vault)) { throw "@Vault directory is missing!" }

    $pluginDirectory = "$($vault)\Plugins\$($plugin)"

    if (!(Test-Path -Path $pluginDirectory)) {
        if (Test-BuiltIn -Plugin $plugin) {
            # Maybe log?
        }
        else {
            if (!$Quiet) {
                Write-Host "Skipping $($plugin), it's either a built-in measure (safe to ignore) or not installed." -ForegroundColor Yellow
            }
        }
        return $false
    }

    $versions = Get-ChildItem -Directory -Path $pluginDirectory | Sort-Object -Descending
    $latestVersion = "$($versions[0].BaseName)"
    $latestPath = "$($pluginDirectory)\$($latestVersion)"
    $latest = [PSCustomObject]@{
        Name    = $plugin
        Version = $latestVersion
        Path    = $latestPath
        x86     = "$($latestPath)\32bit"
        x64     = "$($latestPath)\64bit"
    }
    return $latest
}

function Get-Plugins {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $RootConfig
    )

    $Cache = $MetersOnDemand.Cache
    $SkinPath = $Cache.SkinPath
    $RootConfigPath = "$($SkinPath)\$($RootConfig)"

    $plugins = [pscustomobject]@{}

    $files = Get-ChildItem -Path "$RootConfigPath" -Recurse -File -Include *.inc, *.ini

    $PP = '^\s*(?i)plugin\s*=\s*(.*)$'

    $files | ForEach-Object {
        $lines = $_ | Get-Content
        $lines | ForEach-Object {
            if ($_ -match $PP) {
                $plugin = "$($Matches[1])".ToLower()
                $plugin = $plugin -replace "\.dll$", ""
                $plugin = $plugin -replace "^plugins[\\\/]", ""
                $plugins | Add-Member -MemberType NoteProperty -Name $plugin -Value $true -Force
            }
        }
    }

    $pluginsArray = @()
    $plugins | ToIteratable | ForEach-Object { $pluginsArray += $_.Name }

    return $pluginsArray
}
