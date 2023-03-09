[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]
    $Command = "help",
    [Parameter(Position = 1)]
    [string]
    $Parameter,
    [Alias("v")]
    [Parameter()]
    [switch]
    $Version,
    [Parameter()]
    [string]
    $Skin,
    [Parameter()]
    [string]
    $Query
)

# Self
$Self = @{ Version = "v1.0.0" }
# URLs
$skinsAPI = "https://mond.amv.tools/skins"
# Files
$cacheFile = "$($PSScriptRoot)\cache.json"
$logFile = "$($PSScriptRoot)\mond.log"
$skinFile = "$($PSScriptRoot)\skin.rmskin"
$settingsPath = "$($env:APPDATA)\Rainmeter\Rainmeter.ini"

function Version { Write-Host "MonD $($Self.Version)" }

function Help {

    Version

    $PowerShellVersion = $PSVersionTable.PSVersion
    if ($PowerShellVersion.Major -lt 7) {
        Write-Host "You are running PowerShell $($PowerShellVersion) which is outdated. PowerShell 7 is recommended." -ForegroundColor Yellow
    }

    $commands = @(@{
            Name        = "help"
            Description = "show this help"
        }, @{
            Name        = "update"
            Description = "update the skins list"
            Parameters  = @(@{
                    Name        = "skin"
                    Description = "the full name of the skin to update"
                }
            )
        }, @{
            Name        = "install"
            Description = "installs the specified skin"
            Parameters  = @(@{
                    Name        = "skin" 
                    Description = "the full name of the skin to install"
                })
        }, @{
            Name        = "upgrade"
            Description = "upgrades the specified skin"
            Parameters  = @(@{
                    Name        = "skin" 
                    Description = "the full name of the skin to upgrade"
                })
        }, @{
            Name        = "uninstall"
            Description = "uninstalls the specified skin"
            Parameters  = @(@{
                    Name        = "skin" 
                    Description = "the full name of the skin to uninstall"
                })
        }, 
        @{
            Name        = "search"
            Description = "searches the skin list"
        }, @{
            Name        = "version"
            Description = "prints the MonD version"
        }
    )

    Write-Host "List of MonD commands"
    foreach ($command in $commands) {
        Write-Host "$($command.name)" -ForegroundColor Blue
        Write-Host "$($command.Description)"
        if ($command.Parameters) {
            Write-Host "parameters:" -ForegroundColor Yellow
            foreach ($parameter in $command.Parameters) {
                Write-Host "$($parameter.name)" -ForegroundColor Blue
                Write-Host "$($parameter.Description)"
            }
        }
        Write-Host ""
    }

}

function Get-SkinObject {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [string]
        $FullName
    )

    $Cache = Get-Cache
    $Skins = $Cache.Skins
    $Skin = $Skins[$FullName]

    if (-not $Skin) { throw "No skin named $($FullName) found" }
    return $Skin
}

function Download {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [string]
        $FullName
    )

    $Skin = Get-SkinObject $FullName

    Write-Host "Downloading $($Skin.full_name)"

    Invoke-WebRequest -Uri $Skin.latest_release.browser_download_url -OutFile $skinFile
}

function Install {
    param (
        [Parameter(Position = 0)]
        [string]
        $FullName
    )
    Download $FullName
    Write-Host "Mark skin as installed" -ForegroundColor DarkRed
    Start-Process -FilePath $skinFile
}

function Get-Request {
    param(
        [Parameter(Position = 0)]
        [string]
        $Uri
    )
    try {
        $response = Invoke-WebRequest -Uri $Uri 
        return $response
    }
    catch {
        return $false
    }
}

function Get-Cache {
    $filecontent = Get-Content -Path $cacheFile 
    if ($filecontent) { return $filecontent | ConvertFrom-Json -AsHashtable }
    else { return @{ } }
}

function Update {

    $response = Get-Request $skinsAPI
    if (-not $response) { return Write-Host "Couldn't reach API" }

    $content = $response.Content
    $Skins = $content | ConvertFrom-Json -AsHashtable

    $Cache = Get-Cache
    $Cache["Skins"] = @{}
    if (-not $Cache.Installed) { $Cache["Installed"] = @{} }
    if (-not $Cache.Updateable) { $Cache["Updateable"] = @{} }

    $Skins | % { $Cache.Skins[$_.full_name] = $_ }

    Save-Cache $Cache
    Write-Host "Updated cache file!"

}


function Get-InstalledSkins {
    $settingsContent = Get-Content -Path $settingsPath -Raw

    if ($settingsContent -match 'SkinPath=(.*)') {
        $path = $Matches[0]
        $path = $path -replace '^.*=\s?'
        $path = $path -replace '\\?\s?$'
        $SkinPath = $path
    }
    else { throw "Can't find SkinPath" }

    $Cache = Get-Cache
    $skinFolders = Get-ChildItem -Path "$($SkinPath)" -Directory 
    foreach ($skinFolder in $skinFolders) {
        foreach ($Entry in $Cache.Skins.GetEnumerator()) {
            $Skin = $Entry.Value
            if ($Skin.skin_name -notlike $skinFolder.name) { continue }
            $full_name = $Skin.full_name
            $existing = $Cache.Installed[$full_name]
            $latest = $Skin.latest_release.tag_name
            if ($existing) {
                if ($existing -ne $latest) {
                    $Cache.Updateable[$full_name]
                }
            }
            else {
                $Cache.Installed[$full_name] = $latest
            }
        }
    }

    Save-Cache $Cache
    Write-Host "Updated cache with installed skins!"

}

function Save-Cache {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [hashtable]
        $Cache
    )
    $Cache | ConvertTo-Json -Depth 4 | Out-File -FilePath $cacheFile
}

# NOT IMPLEMENTED

function Search-Skins {
    Write-Host "IMPLEMENT Search-Skins" -ForegroundColor Red
}

function Uninstall {
    param (
        [Parameter(Position = 0)]
        [string]
        $FullName
    )
    $installed = Get-InstalledSkinsTable
    if (-not($installed[$FullName])) { 
        Write-Host "Skin $FullName is not installed"
        return 
    }

    # Get the skin object
    $Skin = Find-Skins -Query $FullName -Exact

    # Remove the skin folder
    $skinsPath = $RmApi.VariableStr("SKINSPATH")
    Remove-Item -Path "$($skinsPath)$($Skin.skin_name)" -Recurse

    # Report results
    Write-Host "Uninstalled $($Skin.full_name)"
    Update-InstalledSkinsTable
    Export
}

# Main body
try {

    # Maybe Get-Cache here or at the top and use it everywhere
    # Save-Cache multiple times, only Get-Cache once

    if ($Version) { return Version }

    switch ($Command) {
        "help" { Help }
        "version" { Version }
        "update" { Update }
        "install" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { throw "Tell me what to install dummy" }
            Install $Parameter
            break
        }
        "upgrade" {
            Write-Host "Implement UPGRADE"
            break
        }
        "uninstall" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { throw "Tell me what to uninstall dummy" }
            Uninstall $Parameter
            break
        }
        "installed" {
            Get-InstalledSkins
            break
        }
        "search" {
            if ($Query) { $Parameter = $Query }
            if (-not $Parameter) { throw "Tell me what to search dummy" }
            Search $Parameter
            break
        }
        Default {
            Write-Host "$Command" -ForegroundColor Red -NoNewline
            Write-Host " is not a command! Use" -NoNewline 
            Write-Host " MonD help " -ForegroundColor Blue -NoNewline
            Write-Host "to see available commands!"
            break
        }
    }
}
catch {
    $_ | Out-File -FilePath $logFile -Append 
    Write-Error $_
}