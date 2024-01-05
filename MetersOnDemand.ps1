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
    [Alias("Config")]
    [string]
    $Skin,
    [Parameter()]
    [string]
    $Query,
    [Parameter()]
    [string]
    $Property,
    [Parameter()]
    [ValidateSet("skin", "layout")]
    [string]
    $LoadType,
    [Parameter()]
    [string]
    $Load,
    [Parameter()]
    [string]
    $VariableFiles,
    [Parameter()]
    [string]
    $MinimumRainmeter,
    [Parameter()]
    [string]
    $MinimumWindows,
    [Parameter()]
    [string]
    $Author,
    [Parameter()]
    [string]
    $HeaderImage,
    [Parameter()]
    [Alias("Version", "v")]
    [string]
    $PackageVersion,
    [Parameter()]
    [Alias("o")]
    [string]
    $OutPath,
    [Parameter()]
    [Alias("name")]
    [string]
    $OutFile,
    [Parameter()]
    [Alias("OutDir", "Directory", "d")]
    [string]
    $OutDirectory,
    [Parameter()]
    [string]
    $Exclude,
    [Parameter()]
    [switch]
    $MergeSkins,
    [Parameter()]
    [switch]
    $Force,
    [Parameter()]
    [switch]
    $Quiet,
    [Parameter()]
    [Alias("Bangs")]
    [string]
    $Bang,
    [Parameter()]
    [Alias("Start")]
    [switch]
    $StartRainmeter,
    [Parameter()]
    [Alias("Stop")]
    [switch]
    $StopRainmeter
)

# Globals
$MetersOnDemand = [PSCustomObject]@{ 
    Version       = "v1.3.0"
    Directory     = "#Mond"
    FileName      = "MetersOnDemand.ps1"
    FullName      = "meters-on-demand/cli"
    SkinName      = "Meters on Demand"
    Wiki          = "https://docs.rainmeter.skin"
    Modules       = "modules"
    Commands      = "commands"
    Api           = [PSCustomObject]@{
        Url       = "https://api.rainmeter.skin"
        Endpoints = [PSCustomObject]@{
            Skins = "https://api.rainmeter.skin/skins"
        }
        Wiki      = "https://docs.rainmeter.skin/api"
    }
    Cache         = [PSCustomObject]@{}
    Config        = [PSCustomObject]@{}
    ScriptRoot    = ""
    TempDirectory = "temp"
    CacheFile     = "cache.json"
    ConfigFile    = "config.json"
    LogFile       = "mond.log"
    SkinFile      = "skin.rmskin"
}

# If running under PSRM in Rainmeter
if ($RmApi) {
    $MetersOnDemand.ScriptRoot = "$($RmApi.VariableStr("SKINSPATH"))$($MetersOnDemand.Directory)"
}
else {
    if (!$PSScriptRoot) {
        throw "`$PSScriptRoot is not set, this should not happen. Please set `$PSScriptRoot = <path to #SKINSPATH##Mond> before calling $($MetersOnDemand.FileName)"
    }
    $MetersOnDemand.ScriptRoot = $PSScriptRoot
}

# Files
$MetersOnDemand.TempDirectory = "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.TempDirectory)"
$MetersOnDemand.CacheFile = "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.CacheFile)"
$MetersOnDemand.ConfigFile = "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.ConfigFile)"
$MetersOnDemand.LogFile = "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.LogFile)"
$MetersOnDemand.SkinFile = "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.SkinFile)"

# Load modules
Get-ChildItem "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.Modules)\*" | ForEach-Object {
    . "$($_)"
}

# Load commands
Get-ChildItem "$($MetersOnDemand.ScriptRoot)\$($MetersOnDemand.Commands)\*" | ForEach-Object {
    . "$($_)"
}

function Update {
    if (!$RmApi) {
        Write-Host "Use " -NoNewline
        Write-Host "Update-SkinList" -NoNewline -ForegroundColor White
        Write-Host " to update the cache file."
        return
    }

    $parentMeasure = $RmApi.GetMeasureName()
    Invoke-Bang "[!PauseMeasure `"$($parentMeasure)`"][!SetOption `"$($parentMeasure)`" UpdateDivider -1]"

    Write-Host "Updating MonD cache!"
    $MetersOnDemand.Cache = Get-Cache
    return $MetersOnDemand.Version
}

function InstallMetersOnDemand {
    try {
        if (!$RmApi) { throw "Meters on Demand can only be installed under PSRM" }

        $SkinPath = "$($RmApi.VariableStr("SKINSPATH"))" -replace "\\$", ""
        $SettingsPath = "$($RmApi.VariableStr("SETTINGSPATH"))" -replace "\\$", ""
        $ConfigEditor = "$($RmApi.VariableStr("CONFIGEDITOR"))" -replace "\\$", ""
        $RainmeterDirectory = "$($RmApi.VariableStr("PROGRAMPATH"))" -replace "\\$", ""
        $ProgramPath = "$($RainmeterDirectory)\Rainmeter.exe"

        Write-Host "Installing Meters on Demand..."
        $RootConfigPath = "$($SkinPath)\$($MetersOnDemand.SkinName)"
        $InstallPath = "$SkinPath\$($MetersOnDemand.Directory)"

        # Load modules from the root path
        Get-ChildItem "$($RootConfigPath)\$($MetersOnDemand.Modules)\*" | ForEach-Object {
            . "$($_)"
        }
        # Load commands from the root path
        Get-ChildItem "$($RootConfigPath)\$($MetersOnDemand.Commands)\*" | ForEach-Object {
            . "$($_)"
        }

        $UserConfig = "$($InstallPath)\config.json"
        $TempConfig = "$($RootConfigPath)\config.json"
        $Config = New-Config
        if (Test-Path $UserConfig) {
            Write-Host "Merging existing user settings"
            $Config = Read-Json -Path $UserConfig | Merge-Object -Source $Config
        }
        Out-Json -Object $Config -Path $TempConfig

        # Clear the InstallPath
        Remove-Item -Path "$($InstallPath)" -Recurse -Force

        # Write debug info
        Write-Host "/////////////////"
        Write-Host "RootConfigPath: $($RootConfigPath)"
        Write-Host "InstallPath: $($InstallPath)"
        Write-Host "SkinPath: $($SkinPath)"
        Write-Host "SettingsPath: $($SettingsPath)"
        Write-Host "ProgramPath: $($ProgramPath)"
        Write-Host "RainmeterDirectory: $($RainmeterDirectory)"
        Write-Host "ConfigEditor: $($ConfigEditor)"
        Write-Host "/////////////////"

        Write-Host "Creating the cache"
        New-Cache | Merge-Object -Override -Source ([PSCustomObject]@{
                SkinPath           = $SkinPath
                SettingsPath       = $SettingsPath
                ProgramPath        = $ProgramPath
                RainmeterDirectory = $RainmeterDirectory
                ConfigEditor       = $ConfigEditor
            }) | Add-SkinLists | Save-Cache -Path "$($RootConfigPath)\cache.json" -Quiet

        Write-Host "Copying script files from '$RootConfigPath' to '$InstallPath'"
        New-Item -ItemType Directory -Path "$($InstallPath)"
        # Copy directories
        Copy-Item -Path "$($RootConfigPath)\commands" -Destination "$($InstallPath)" -Recurse -Force
        Copy-Item -Path "$($RootConfigPath)\modules" -Destination "$($InstallPath)" -Recurse -Force
        # Copy loose files
        Get-ChildItem -Path "$($RootConfigPath)\*" -File -Include "*.ps1", "*.bat", "*.json" | Copy-Item -Destination "$($InstallPath)"

        Write-Host "Adding '$InstallPath' to PATH"
        Set-PathVariable -AddPath $InstallPath

        Write-Host "Successfully installed MonD $($MetersOnDemand.Version)!"

        if ($RmApi) {
            Invoke-Bang "[!About][!DeactivateConfig]"
        }
    }
    catch {
        Write-Exception -Exception $_ -Breaking
    }
}

# Main body
if ($RmApi) { 
    if ($RmApi.Variable("MetersOnDemand.Install") -eq 1) {
        try {
            InstallMetersOnDemand
        }
        catch {
            $RmApi.LogError("$($_)")
            $_ | Out-File -FilePath $MetersOnDemand.LogFile -Append
            $RmApi.Bang("[`"$($MetersOnDemand.LogFile)`"]")
        }
    }
    return
}
try {
    $isDotSourced = $MyInvocation.InvocationName -eq '.'

    # Commands that do not need the cache
    if (($Command -eq "help") -and !$isDotSourced) { return Help }
    if ($Command -eq "version") { return Version }

    # Read the cache and config
    $MetersOnDemand.Cache = Get-Cache
    $MetersOnDemand.Config = Get-Config

    if ($isDotSourced) { return }

    # Mond alias
    if (@("install", "upgrade", "search").Contains($Command)) {
        if ($Skin -like "mond") { $Skin = $MetersOnDemand.FullName }
        if ($Parameter -like "mond") { $Parameter = $MetersOnDemand.FullName }
    }

    switch ($Command) {
        "update" {
            if ($Skin) { $Parameter = $Skin }
            if ($Parameter) {
                Write-Host "Use '" -NoNewline -ForegroundColor Gray
                Write-Host "mond upgrade $Parameter" -ForegroundColor White -NoNewline
                Write-Host "' to upgrade a skin."
                return
            }
            Get-Cache | Add-SkinLists | Save-Cache -Quiet
            Write-Host "Cache updated!"
            break
        }
        "install" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) {
                throw "Install requires the named parameter -Skin (Position = 1)"
            }
            Install -FullName $Parameter -Force:$Force -FirstMatch
            break
        }
        "list" {
            $Skins = @()
            (ToIteratable -Object $MetersOnDemand.Cache.Installed) | ForEach-Object {
                $Skins += Get-SkinObject -FullName $_.name
            }
            Format-SkinList -Skins $Skins
            break
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
            Uninstall -FullName $Parameter -Force:$Force
            break
        }
        "restore" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) {
                throw "Restore requires the named parameter -Skin (Position = 1)"
            }
            Restore -FullName $Parameter -Force:$Force
            break
        }
        "init" {
            if ($Skin) { $Parameter = $Skin }
            if (-not $Parameter) {
                throw "Usage: mond init SkinName"
            }
            New-Skin -SkinName $Parameter
            break
        }
        "refresh" {
            Refresh
            break
        }
        "lock" {
            $RootConfig = Assert-RootConfig
            New-Lock -RootConfig $RootConfig
        }
        "package" {
            Limit-PowerShellVersion
            $RootConfig = Assert-RootConfig
            New-Package -RootConfig "$RootConfig"
            break
        }
        "search" {
            if ($Query) { $Parameter = $Query }
            if ($Property) { $Option = $Property }
            Search -Query $Parameter -Property $Option
            break
        }
        "config" {
            if ($Parameter -and $Option) {
                return Set-Config $Parameter $Option
            }
            if ($Parameter) {
                return Write-ConfigOption $Parameter 
            }
            Write-FormattedConfig
            break
        }
        "bang" {
            if ($Parameter -and !$Bang) { $Bang = $Parameter }
            return Invoke-Bang -Bang $Bang -StartRainmeter:$StartRainmeter -StopRainmeter:$StopRainmeter
            break
        }
        Default {
            Test-DevCommand
            break
        }
    }
}
catch {
    $_ | Out-File -FilePath $MetersOnDemand.LogFile -Append 
    # Write-Host $_
    Write-Error $_
    Write-Host $_.ScriptStackTrace
}
