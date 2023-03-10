[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]
    $Command = "help",
    [Parameter(Position = 1)]
    [string]
    $Parameter,
    [Parameter(Position = 2)]
    [string]
    $Option,
    [Parameter()]
    [string]
    $Skin,
    [Parameter()]
    [string]
    $Query,
    [Parameter()]
    [string]
    $Property,
    [Alias("v")]
    [Parameter()]
    [switch]
    $Version,
    [Parameter()]
    [switch]
    $Force
)

# Globals
$Self = @{ Version = "v1.0.0" }
$Cache = @{ }
$Removed = "@Backup"

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
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force
    )

    $installed = $Cache.Installed[$FullName]
    if ($installed -and (-not $Force)) {
        throw "$($FullName) is already installed. Use -Force to reinstall."
    }

    $Skin = Get-SkinObject -FullName $FullName
    $latest = $Skin.latest_release.tag_name
    if ($installed -ne $latest) {
        $Cache.Installed[$FullName] = $latest
        $Cache.Updateable.Remove($FullName)
        Save-Cache $Cache
    }

    Download $FullName
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
    if (-not $filecontent) { return @{ } }
    return $filecontent | ConvertFrom-Json -AsHashtable
}

function Update {
    $Cache = Get-Cache

    $response = Get-Request $skinsAPI
    if (-not $response) { 
        Write-Host "Couldn't reach API, using cache..." -ForegroundColor Yellow
        return $Cache
    }

    $content = $response.Content
    $Skins = $content | ConvertFrom-Json -AsHashtable

    $Cache["Skins"] = @{}
    $Skins | % { $Cache.Skins[$_.full_name] = $_ }

    if (-not $Cache.Installed) { $Cache["Installed"] = @{} }
    if (-not $Cache.Updateable) { $Cache["Updateable"] = @{} }

    Get-InstalledSkins
    Save-Cache $Cache
    return $Cache
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
                    $Cache.Updateable[$full_name] = $latest
                }
            }
            else {
                $Cache.Installed[$full_name] = $latest
            }
        }
    }

    $Cache.SkinPath = $SkinPath

}

function Save-Cache {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [hashtable]
        $Cache
    )
    $Cache | ConvertTo-Json -Depth 4 | Out-File -FilePath $cacheFile
}

function RemovedDirectory {
    $skinPath = $Cache.SkinPath
    $removedDirectory = "$($skinPath)\$($Removed)"
    if (-not(Test-Path -Path $removedDirectory)) {
        New-Item -Path $removedDirectory -ItemType Directory
    }
    return $removedDirectory
}

function Uninstall {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force
    )

    $installed = $Cache.Installed[$FullName]
    if (-not $installed) { 
        if ($Force) { return }
        throw "Skin $FullName is not installed"
    }

    $skinPath = $Cache.SkinPath
    $skinName = $Cache.Skins[$FullName].skin_name

    $removedDirectory = RemovedDirectory
    $path = "$($skinPath)\$($skinName)"
    $target = "$($removedDirectory)\$($skinName)"
    if (Test-Path -Path "$($target)") {
        Remove-Item -Path "$($target)" -Recurse -Force
    }
    Move-Item -Path "$($path)" -Destination $removedDirectory

    # Update cache
    $Cache.Installed.Remove($FullName)
    $Cache.Updateable.Remove($FullName)
    Save-Cache $Cache

    # Report results
    Write-Host "Uninstalled $($FullName)"
}

function Restore {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force
    )

    $skinPath = $Cache.SkinPath
    $skinName = $Cache.Skins[$FullName].skin_name

    $removedDirectory = RemovedDirectory
    $restorePath = "$($removedDirectory)\$($skinName)"
    $restoreTarget = "$($skinPath)\$($skinName)"
    if (-not (Test-Path -Path "$($restorePath)")) {
        if ($Force) { return }
        throw "Cannot restore: $($FullName) was not found in $($Removed)."
    }
    if (Test-Path -Path "$($restoreTarget)") {
        if ($Force) {
            Remove-Item -Path "$($restoreTarget)" -Recurse -Force
        }
        else {
            throw "Cannot restore: $($FullName) is already installed. Use -Force to overwrite."
        }
    }
    Move-Item -Path "$($restorePath)" -Destination $skinPath -Force

    # Update cache
    Get-InstalledSkins
    Save-Cache $Cache

    # Report results
    Write-Host "Restored $($FullName)"
}

function Upgrade {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName
    )

    $Skin = Get-SkinObject $FullName

    $installed = $Cache.Installed[$Skin.full_name]

    if (-not $installed) {
        throw "$($FullName) is not installed"
    }
    if (-not $Cache.Updateable[$Skin.full_name]) {
        throw "$($FullName) $($installed) is the latest version"
    }

    Install -FullName $FullName -Force

}

function Search {
    param (
        [Parameter(Position = 0)]
        [string]
        $Query,
        [Parameter(Position = 1)]
        [string]
        $Property
    )
    if (-not $Query) { $Query = ".*" }
    if (-not $Property) { $Property = "full_name" }

    $Results = @()
    foreach ($Entry in $Cache.Skins.GetEnumerator()) {
        $Skin = $Entry.Value
        if ($Skin[$Property] -match $Query) { $Results += $Skin }
    }
    return $Results
}

# Main body
try {

    # Commands that do not need the cache
    if ($Version) { return Version }
    if ($Command -eq "version") { return Version }
    if ($Command -eq "help") { return Help }

    $Cache = Update

    switch ($Command) {
        "update" { Write-Host "Cache updated!" }
        "install" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Install requires the named parameter -Skin (Position = 1)"
            }
            Install $Parameter -Force:$Force
            break
        }
        "upgrade" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Upgrade requires the named parameter -Skin (Position = 1)"
            }
            Upgrade -FullName $Parameter
            break
        }
        "uninstall" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Uninstall requires the named parameter -Skin (Position = 1)"
            }
            Uninstall $Parameter -Force:$Force
            break
        }
        "restore" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Restore requires the named parameter -Skin (Position = 1)"
            }
            Restore $Parameter -Force:$Force
            break
        }
        "search" {
            if ($Query) { $Parameter = $Query }
            if ($Property) { $Option = $Property }
            $found = Search -Query $Parameter -Property $Option 

            if (-not $found) { throw "No skins found." }

            Write-Host "Found skins: "
            $found | % {
                Write-Host $_.full_name -ForegroundColor Blue -NoNewline
                $current = $_.latest_release.tag_name
                $versionColor = "White"
                $installed = $Cache.Installed[$_.full_name]
                $updateable = $Cache.Updateable[$_.full_name]
                if ($installed) {
                    $current = $installed
                    $versionColor = "Green"
                }
                Write-Host " $($current)" -ForegroundColor $versionColor -NoNewline

                if ($updateable) { Write-Host " ($($updateable) available)" -ForegroundColor Yellow }
                else { Write-Host "" }

                Write-Host $_.description
            }            
            
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