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
    [Parameter()]
    [string]
    $SkinPath,
    [Parameter()]
    [switch]
    $FirstTimeInstall,
    [Alias("v")]
    [Parameter()]
    [switch]
    $Version,
    [Parameter()]
    [switch]
    $Force
)

# Globals
$Self = [PSCustomObject]@{ 
    Version     = "v1.1.0";
    Directory   = "#MonD"; 
    FileName    = "MetersOnDemand.ps1"; 
    BatFileName = "mond.bat"
}
$Cache = $false
$Removed = "@Backup"

# URLs
$skinsAPI = "https://mond.amv.tools/skins"

# Files
$cacheFile = "$($PSScriptRoot)\cache.json"
$logFile = "$($PSScriptRoot)\mond.log"
$skinFile = "$($PSScriptRoot)\skin.rmskin"
$settingsPath = "$($env:APPDATA)\Rainmeter\Rainmeter.ini"

# If running under PSRM in Rainmeter
if (!$PSScriptRoot) {
    if (!$RmApi) { throw "`$PSScriptRoot is not set" }
    $SkinPath = $($RmApi.VariableStr("SKINSPATH"))
    $ScriptRoot = "$SkinPath$($Self.Directory)"
    $cacheFile = "$($ScriptRoot)\cache.json"
    $logFile = "$($ScriptRoot)\mond.log"
    $skinFile = "$($ScriptRoot)\skin.rmskin"
    $settingsPath = "$($RmApi.VariableStr("SETTINGSPATH"))Rainmeter.ini"

    # Write-Host $cacheFile
    # Write-Host $logFile
    # Write-Host $skinFile
    # Write-Host $settingsPath
    # Write-Host $SkinPath

}

function Update {    
    if (!$RmApi) { 
        Write-Host "Use " -NoNewline Gray
        Write-Host "Update-Cache" -NoNewline -ForegroundColor White
        Write-Host " to update the cache file."
        return
    }

    $parentMeasure = $RmApi.GetMeasureName()
    $RmApi.Bang("[!PauseMeasure `"$($parentMeasure)`"][!SetOption `"$($parentMeasure)`" UpdateDivider -1]")
    
    Write-Host "Updating MonD cache!"
    Update-Cache
    return $Self.Version
}

function Version { Write-Host "MonD $($Self.Version)" -ForegroundColor Blue }

function Help {

    $PowerShellVersion = $PSVersionTable.PSVersion
    if ($PowerShellVersion.Major -lt 5) {
        Write-Host "You are running PowerShell $($PowerShellVersion) which is outdated. PowerShell 5 or 7 is recommended.`n" -ForegroundColor Yellow
    }

    # $skinSig = "[[-Skin] <full_name>]"
    $skinSig = "[-Skin] <full_name>"
    $forceSig = "[-Force]"

    $commands = @(
        [pscustomobject]@{
            Name        = "update"
            Signature   = "$forceSig"
            Description = "updates the skins list"
        }, 
        [pscustomobject]@{
            Name        = "install"
            Signature   = "$skinSig $forceSig"
            Description = "installs the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "search"
            Signature   = "[-Query] <keyword> [-Property <property>]"
            Description = "searches the skin list"
        }, 
        [pscustomobject]@{
            Name        = "upgrade"
            Signature   = "$skinSig $forceSig"
            Description = "upgrades the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "uninstall"
            Signature   = "$skinSig $forceSig"
            Description = "uninstalls the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "version"
            Signature   = ""
            Description = "prints the MonD version"
        },
        [pscustomobject]@{
            Name        = "help"
            Signature   = "[-Command]"
            Description = "show this help"
        }
    )

    Write-Host "MonD" -ForegroundColor White -NoNewline
    Write-Host " $($Self.Version) " -ForegroundColor Blue -NoNewline
    Write-Host "list of commands`n" -ForegroundColor White

    foreach ($command in $commands) {
        Write-Host "$($command.name) " -ForegroundColor White -NoNewline
        Write-Host "$($command.signature) " -ForegroundColor Gray
        Write-Host " $($command.Description)" -ForegroundColor Gray -NoNewline
        Write-Host "`n"
    }

    Write-Host "Also check out the MonD wiki! " -NoNewline
    Write-Host "https://github.com/meters-on-demand/mond-api/wiki" -ForegroundColor Blue -NoNewline
    Write-Host "`n"

}

function Get-SkinObject {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [psobject]
        $Cache
    )
    if (!$Cache) { $Cache = Update-Cache -SkipInstalled }

    $Skins = $Cache.Skins
    $Skin = $Skins.$FullName

    if (-not $Skin) { throw "No skin named $($FullName) found" }
    return $Skin
}

function Download {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [psobject]
        $Cache
    )
    if (!$Cache) { $Cache = Update-Cache -SkipInstalled }

    $Skin = Get-SkinObject $FullName -Cache $Cache

    Write-Host "Downloading $($Skin.full_name)"

    Invoke-WebRequest -Uri $Skin.latest_release.browser_download_url -OutFile $skinFile

    return $skinFile
}

function Install {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [pscustomobject]
        $Cache,
        [Parameter()]
        [switch]
        $Force
    )
    if (!$Cache) { $Cache = Update-Cache }

    $installed = $Cache.Installed.$FullName
    if ($installed -and (-not $Force)) {
        return Write-Host "$($FullName) is already installed. Use -Force to reinstall." -ForegroundColor Yellow
    }

    $Skin = Get-SkinObject -FullName $FullName -Cache $Cache
    $latest = $Skin.latest_release.tag_name

    $Installed = $Cache.Installed
    if ($installed -ne $latest) {
        $Installed | Add-Member -MemberType NoteProperty -Name "$FullName" -Value $latest -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "Installed" -Value $Installed -Force
        $Cache.Updateable.psobject.properties.Remove($FullName)
        $Cache = Save-Cache $Cache
    }

    Download -FullName $FullName -Cache $Cache
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

    $Cache = [PSCustomObject]@{
        Skins      = [pscustomobject]@{ };
        Installed  = [pscustomobject]@{ };
        Updateable = [pscustomobject]@{ };
    }

    if (Test-Path -Path $cacheFile) {
        $Cache = Get-Content -Path $cacheFile  | ConvertFrom-Json
    }

    if (!$Cache.SkinPath) {
        if (!(Test-Path -Path $settingsPath)) { 
            return Write-Host "Can't find Rainmeter.ini. <insert link to wiki>" -ForegroundColor Red
        }
        $settingsContent = Get-Content -Path $settingsPath -Raw
        if ($settingsContent -match 'SkinPath=(.*)') {
            $path = $Matches[0]
            $path = $path -replace '^.*=\s?'
            $path = $path -replace '\\?\s?$'
            $Cache | Add-Member -MemberType NoteProperty -Name "SkinPath" -Value $path -Force
        }
        else { throw "Can't find SkinPath in Rainmeter.ini" }
    }

    return $Cache

}

function Update-Cache {
    param (
        [Parameter()]
        [switch]
        $SkipInstalled,
        [Parameter()]
        [switch]
        $Force
    )
    if ($Cache -and !$Force) { return $Cache }

    $Cache = Get-Cache
    
    $CurrentDate = Get-Date -Format "MM-dd-yy"
    if (!$Force -and ($Cache.LastChecked -eq $CurrentDate)) {
        if (!$SkipInstalled) { $Cache = Get-InstalledSkins -Cache $Cache }
        return $Cache 
    }

    $response = Get-Request $skinsAPI
    if (-not $response) { 
        Write-Host "Couldn't reach API, using cache..." -ForegroundColor Yellow
        if (!$SkipInstalled) { $Cache = Get-InstalledSkins -Cache $Cache }
        return $Cache
    }

    $SkinsArray = $response.Content | ConvertFrom-Json
    # PSCustomObject bullshit
    $Skins = [PSCustomObject]@{ }
    $SkinsArray | % {
        $Skins | Add-Member -MemberType NoteProperty -Name "$($_.full_name)" -Value $_
    }

    $Cache | Add-Member -MemberType NoteProperty -Name 'Skins' -Value $Skins -Force
    $Cache | Add-Member -MemberType NoteProperty -Name 'LastChecked' -Value $CurrentDate -Force

    if (-not $Cache.Installed) { $Cache | Add-Member -MemberType NoteProperty -Name 'Installed' -Value ([PSCustomObject] @{ }) }
    if (-not $Cache.Updateable) { $Cache | Add-Member -MemberType NoteProperty -Name 'Updateable' -Value ([PSCustomObject] @{ }) }

    $Cache = Get-InstalledSkins -Cache $Cache

    return Save-Cache $Cache
}

function Get-InstalledSkins {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Cache
    )

    $SkinPath = $Cache.SkinPath
    $Installed = $Cache.Installed
    $Updateable = [PSCustomObject]@{ }

    if (!(Test-Path -Path $SkinPath)) {
        throw "SkinPath ($SkinPath) does not exist"
    }

    $skinFolders = Get-ChildItem -Path "$($SkinPath)" -Directory 
    $IteratableSkins = ToIteratable -Object $Cache.Skins
    foreach ($skinFolder in $skinFolders) {
        foreach ($Entry in $IteratableSkins) {
            $Skin = $Entry.Value
            if ($Skin.skin_name -notlike $skinFolder.name) { continue }
            $full_name = $Skin.full_name
            $existing = $Cache.Installed.$full_name
            $latest = $Skin.latest_release.tag_name
            if ($existing) {
                if ($existing -ne $latest) { 
                    $Updateable | Add-Member -MemberType NoteProperty -Name "$full_name" -Value $latest
                }
            }
            else { 
                $Installed | Add-Member -MemberType NoteProperty -Name "$full_name" -Value $latest
            }
        }
    }

    $Cache | Add-Member -MemberType noteproperty -Name 'Installed' -Value $Installed -Force
    $Cache | Add-Member -MemberType noteproperty -Name 'Updateable' -Value $Updateable -Force

    return $Cache

}

function Save-Cache {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [PSCustomObject]
        $Cache
    )
    $Cache | ConvertTo-Json -Depth 4 | Out-File -FilePath $cacheFile
    return $Cache
}

function RemovedDirectory {
    param (
        [Parameter(Mandatory)]
        [string]
        $SkinPath
    )

    $removedDirectory = "$($SkinPath)\$($Removed)"
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
        [Parameter(Mandatory)]
        [psobject]
        $Cache,
        [Parameter()]
        [switch]
        $Force
    )
    if (!$Cache) { $Cache = Update-Cache }

    $installed = $Cache.Installed.$FullName
    if (-not $installed) { 
        if ($Force) { return }
        throw "Skin $FullName is not installed"
    }

    $skinPath = $Cache.SkinPath
    $skinName = $Cache.Skins.$FullName.skin_name

    $removedDirectory = RemovedDirectory -SkinPath $skinPath
    $path = "$($skinPath)\$($skinName)"
    $target = "$($removedDirectory)\$($skinName)"
    if (Test-Path -Path "$($target)") {
        Remove-Item -Path "$($target)" -Recurse -Force
    }
    Move-Item -Path "$($path)" -Destination $removedDirectory

    # Update cache
    $Cache.Installed.psobject.properties.Remove($FullName)
    $Cache.Updateable.psobject.properties.Remove($FullName)
    $Cache = Save-Cache $Cache

    # Report results
    Write-Host "Uninstalled $($FullName)"
    Write-Host "Use 'mond restore $($FullName)' to restore"
}

function Restore {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [psobject]
        $Cache,
        [Parameter()]
        [switch]
        $Force
    )
    if (!$Cache) { $Cache = Update-Cache }
    
    $skinPath = $Cache.SkinPath
    $skinName = $Cache.Skins.$FullName.skin_name

    $removedDirectory = RemovedDirectory -SkinPath $skinPath
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
    $Cache = Get-InstalledSkins -Cache $Cache
    $Cache = Save-Cache $Cache

    # Report results
    Write-Host "Restored $($FullName)"
}

function Upgrade {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force
    )
    if (!$Cache) { $Cache = Update-Cache }

    $Skin = Get-SkinObject $FullName

    $installed = $Cache.Installed.($Skin.full_name)

    if (!$installed) {
        throw "$($FullName) is not installed"
    }
    if (!$Force -and !($Cache.Updateable.($Skin.full_name))) {
        throw "$($FullName) $($installed) is the latest version"
    }

    Install -FullName $FullName -Cache $Cache -Force

}

function Search {
    param (
        [Parameter(Position = 0)]
        [string]
        $Query,
        [Parameter(Position = 1)]
        [string]
        $Property,
        [Parameter(Mandatory)]
        [psobject]
        $Cache
    )
    if (!$Query) { $Query = ".*" }
    if (!$Property) { $Property = "full_name" }

    if (!$Cache) { $Cache = Update-Cache }

    Write-Host "Searching for `"$Query`""

    $Results = @()
    foreach ($Entry in ToIteratable -Object $Cache.Skins ) {
        $Skin = $Entry.Value
        if ($Skin.$Property -match $Query) { $Results += $Skin }
    }
    return $Results
}

function ToIteratable {
    param(
        [Parameter(Mandatory, Position = 1)]
        [pscustomobject]
        $Object
    )
    $Members = $Object.psobject.Members | Where-Object membertype -like 'noteproperty'
    return $Members
}

# https://github.com/ThePoShWolf/Utilities/blob/master/Misc/Set-PathVariable.ps1
# Added |^$ to filter out empty items in $arrPath
# Removed the $Scope param and added a static [System.EnvironmentVariableTarget]::User
function Set-PathVariable {
    param (
        [string]$AddPath,
        [string]$RemovePath
    )

    $Scope = [System.EnvironmentVariableTarget]::User

    $regexPaths = @()
    if ($PSBoundParameters.Keys -contains 'AddPath') {
        $regexPaths += [regex]::Escape($AddPath)
    }
    
    if ($PSBoundParameters.Keys -contains 'RemovePath') {
        $regexPaths += [regex]::Escape($RemovePath)
    }
        
    $arrPath = [System.Environment]::GetEnvironmentVariable('PATH', $Scope) -split ';'
    foreach ($path in $regexPaths) {
        $arrPath = $arrPath | Where-Object { $_ -notMatch "^$path\\?| ^$" }
    }
    $value = ($arrPath + $addPath) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $value, $Scope)
}

function InstallMonD {    

    Write-Host "DEBUG INFORMATION"
    Write-Host "/////////////////"
    Write-Host "Self: " -NoNewline
    Write-Host $Self
    Write-Host "PSScriptRoot: " -NoNewline
    Write-Host $PSScriptRoot
    Write-Host "SkinPath: " -NoNewline
    Write-Host $SkinPath
    Write-Host "/////////////////"

    Write-Host "`nInstalling MonD..."

    # Remove trailing \
    $SkinPath = $SkinPath -replace "\\$", ""

    $InstallPath = "$SkinPath\$($Self.Directory)"
    if (!(Test-Path $SkinPath)) { throw "SkinPath doesn't exist???" }
    if (!(Test-Path $InstallPath)) { New-Item -ItemType Directory -Path $InstallPath }

    Write-Host "`nCopying '$($Self.FileName)' & '$($Self.BatFileName)' to '$InstallPath'"

    Copy-Item -Path "$PSScriptRoot\$($Self.FileName)" -Destination $InstallPath
    Copy-Item -Path "$PSScriptRoot\$($Self.BatFileName)" -Destination $InstallPath

    Write-Host "`nAdding '$InstallPath' to PATH"
    Set-PathVariable -AddPath $InstallPath

    Write-Host "`nSuccessfully installed MonD $($Self.Version)"

}

# Main body
if ($RmApi) { return }
try {

    if ($FirstTimeInstall) { return InstallMonD }

    # Commands that do not need the cache
    if ($Version) { return Version }
    if ($Command -eq "version") { return Version }
    if ($Command -eq "help") { return Help }

    # Create the cache
    if ($Command -eq "update") { $Force = $True }
    $Cache = Update-Cache -Force:$Force

    switch ($Command) {
        "update" {
            if ($Skin) { $Parameter = $Skin }
            if ($Parameter) { 
                Write-Host "Use '" -NoNewline -ForegroundColor Gray
                Write-Host "mond upgrade $Parameter" -ForegroundColor White -NoNewline
                Write-Host "' to upgrade a skin."
                return
            }
            Write-Host "Cache updated!"
        }
        "install" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Install requires the named parameter -Skin (Position = 1)"
            }
            Install -FullName $Parameter -Cache $Cache -Force:$Force
            break
        }
        "list" {
            $Installed = $Cache.Installed 
            ToIteratable -Object $Installed | % { Write-Host $_.Name }
        }
        "upgrade" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Upgrade requires the named parameter -Skin (Position = 1)"
            }
            Upgrade -FullName $Parameter -Force:$Force
            break
        }
        "uninstall" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Uninstall requires the named parameter -Skin (Position = 1)"
            }
            Uninstall -FullName $Parameter -Cache $Cache -Force:$Force
            break
        }
        "restore" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) { 
                throw "Restore requires the named parameter -Skin (Position = 1)"
            }
            Restore -FullName $Parameter -Cache $Cache -Force:$Force
            break
        }
        "search" {
            if ($Query) { $Parameter = $Query }
            if ($Property) { $Option = $Property }

            $found = Search -Query $Parameter -Property $Option -Cache $Cache

            if (-not $found) { return Write-Host "No skins found." }

            Write-Host "Found $($found.length) skins: `n"

            $found | % {
                Write-Host $_.full_name -ForegroundColor Blue -NoNewline
                $current = $_.latest_release.tag_name
                $versionColor = "Gray"
                $installed = $Cache.Installed.($_.full_name)
                $updateable = $Cache.Updateable.($_.full_name)
                if ($installed) {
                    $current = $installed
                    $versionColor = "Green"
                }
                Write-Host " $($current)" -ForegroundColor $versionColor -NoNewline

                if ($updateable) { Write-Host " ($($updateable) available)" -ForegroundColor Yellow }
                else { Write-Host "" }

                Write-Host "$($_.description)`n"
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
    Write-Host $_
}