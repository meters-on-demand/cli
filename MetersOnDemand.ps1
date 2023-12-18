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
    [string]
    $SkinPath,
    [Parameter()]
    [string]
    $ProgramPath,
    [Parameter()]
    [string]
    $ConfigEditor,
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
    [string]
    $SettingsPath,
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
    $Force
)

# Globals
$Self = [PSCustomObject]@{ 
    Version       = "v1.3.0"
    Directory     = "#Mond"
    FileName      = "MetersOnDemand.ps1"
    BatFileName   = "mond.bat"
    TempDirectory = "#Mond\temp"
    Repository    = "meters-on-demand/cli"
    Wiki          = "https://docs.rainmeter.skin"
    Modules       = "modules"
    Commands      = "commands"
    CacheFile     = "cache.json"
}

$Installer = [PSCustomObject]@{
    SkinName = "Meters on Demand"
}

$Api = [PSCustomObject]@{
    Url       = "https://api.rainmeter.skin"
    Endpoints = [PSCustomObject]@{
        Skins = "https://api.rainmeter.skin/skins"
    }
    Wiki      = "https://docs.rainmeter.skin/api"
}

$Commands = [PSCustomObject]@{
    Name = "Value"
}

$Cache = $false
$Removed = "@Backup"

# If running under PSRM in Rainmeter
if ($RmApi) {
    $SkinPath = "$($RmApi.VariableStr("SKINSPATH"))"
    $SettingsPath = "$($RmApi.VariableStr("SETTINGSPATH"))"
    $ConfigEditor = "$($RmApi.VariableStr("CONFIGEDITOR"))"
    $RainmeterDirectory = "$($RmApi.VariableStr("PROGRAMPATH"))"
    $ProgramPath = "$($RainmeterDirectory)Rainmeter.exe"
    $IsInstaller = $RmApi.Variable("MetersOnDemand.Install") -eq 1
    # The installed ScriptRoot
    $ScriptRoot = "$SkinPath$($Self.Directory)"
    # For copying the script files from the right place
    $RootConfigPath = "$($RmApi.VariableStr("ROOTCONFIGPATH"))" -replace "\\$"
}
else { 
    if (!$PSScriptRoot) {
        throw "`$PSScriptRoot is not set??? Where am I?? Where is `$SkinPath\$($Self.Directory)???" 
    }
    $ScriptRoot = $PSScriptRoot
    $RootConfigPath = $PSScriptRoot
}

# Files
$cacheFile = "$($ScriptRoot)\$($Self.CacheFile)"
$logFile = "$($ScriptRoot)\mond.log"
$skinFile = "$($ScriptRoot)\skin.rmskin"

# Load modules
Get-ChildItem "$($RootConfigPath)\$($Self.Modules)\*" | % {
    . "$($_)"
}

# Load commands
Get-ChildItem "$($RootConfigPath)\$($Self.Commands)\*" | % {
    . "$($_)"
}

function Update {
    if (!$RmApi) {
        Write-Host "Use " -NoNewline
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

function InstallMetersOnDemand {
    try {
        # When not running under PSRM
        if (!$RmApi) {
            $MissingParameters = $False   
            if (!$SkinPath) { 
                Write-Error "Please provide the path to the Skins folder in the -SkinPath parameter." 
                $MissingParameters = $True
            }
            if (!(Test-Path $SkinPath)) { 
                Write-Error "SkinPath '$($SkinPath)' doesn't exist." 
                $MissingParameters = $True
            }
            if (!$SettingsPath) { 
                Write-Error "Please provide the path to Rainmeter.ini in the -SettingsPath parameter." 
                $MissingParameters = $True
            }
            if (!$ProgramPath) { 
                Write-Error "Please provide the path to Rainmeter.exe in the -ProgramPath parameter." 
                $MissingParameters = $True
            }
            if (!$ConfigEditor) { 
                Write-Error "Please provide the path to the executable of your desired ConfigEditor in the -ConfigEditor parameter."
                Write-Error "For example: -ConfigEditor `"C:\Users\Reseptivaras\AppData\Local\Programs\Microsoft VS Code\Code.exe`"" 
                $MissingParameters = $True
            }
            if ($MissingParameters) {
                throw "One or multiple required parameters are missing!"
            }
            $RainmeterDirectory = Split-Path -Path $ProgramPath -Parent
        }

        Write-Host "Installing Meters on Demand..."

        # Remove trailing \ from Rainmeter paths
        $SkinPath = "$SkinPath" -replace "\\$", ""
        $SettingsPath = "$SettingsPath" -replace "\\$", ""
        $RootConfigPath = "$RootConfigPath" -replace "\\$", ""
        $RainmeterDirectory = "$RainmeterDirectory" -replace "\\$", ""

        $InstallPath = "$SkinPath\$($Self.Directory)"
        if (Test-Path -Path $InstallPath) {
            Remove-Item -Path $InstallPath -Recurse
            New-Item -Path $InstallPath -ItemType Directory
        }
        else {
            New-Item -ItemType Directory -Path $InstallPath 
        }

        # Write debug info
        Write-Host "/////////////////"
        Write-Host "Self $($Self)"
        Write-Host "ScriptRoot: $($ScriptRoot)"
        Write-Host "RootConfigPath: $($RootConfigPath)"
        Write-Host "SkinPath: $($SkinPath)"
        Write-Host "SettingsPath: $($SettingsPath)"
        Write-Host "ProgramPath: $($ProgramPath)"
        Write-Host "RainmeterDirectory: $($RainmeterDirectory)"
        Write-Host "ConfigEditor: $($ConfigEditor)"
        Write-Host "/////////////////"

        Write-Host "Creating the cache"
        $Cache = New-Cache
        $Cache | Add-Member -MemberType NoteProperty -Name "SkinPath" -Value "$SkinPath" -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "SettingsPath" -Value "$SettingsPath" -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "ProgramPath" -Value "$ProgramPath" -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "RainmeterDirectory" -Value "$RainmeterDirectory" -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "ConfigEditor" -Value "$ConfigEditor" -Force
        $Cache = Update-Cache -Cache $Cache -Force
        $Cache = Save-Cache -Cache $Cache

        Write-Host "Copying script files to '$InstallPath'"
        Write-Host "Copying $($Self.FileName)"
        Copy-Item -Path "$($RootConfigPath)\$($Self.FileName)" -Destination $InstallPath -Force
        Write-Host "Copying $($Self.BatFileName)"
        Copy-Item -Path "$($RootConfigPath)\$($Self.BatFileName)" -Destination $InstallPath -Force
        Write-Host "Copying $($Self.Modules)"
        Copy-Item -Path "$($RootConfigPath)\$($Self.Modules)" -Recurse -Destination $InstallPath -Force
        Write-Host "Copying $($Self.Commands)"
        Copy-Item -Path "$($RootConfigPath)\$($Self.Commands)" -Recurse -Destination $InstallPath -Force
        Write-Host "Copying $($Self.CacheFile)"
        Copy-Item -Path "$($cacheFile)" -Destination $InstallPath -Force

        Write-Host "Adding '$InstallPath' to PATH"
        Set-PathVariable -AddPath $InstallPath

        Write-Host "Successfully installed MonD $($Self.Version)!"

        if ($RmApi) {
            $RmApi.Bang('[!About][!DeactivateConfig]')
        }
    }
    catch {
        Write-Exception -Exception $_ -Breaking
    }
}

# Main body
if ($RmApi) { 
    if ($IsInstaller) {
        try {
            InstallMetersOnDemand
        }
        catch {
            $RmApi.LogError("$($_)")
            $_ | Out-File -FilePath $logFile -Append
            $RmApi.Bang("[`"$($logFile)`"]")
        }
    }
    return 
}
try {
    # Commands that do not need the cache
    if ($Command -eq "version") { return Version }
    if ($Command -eq "help") { return Help }

    # Create the cache
    if ($Command -eq "update") { $Force = $True }
    $Cache = Update-Cache -Force:$Force

    # Mond alias
    if (@("install", "upgrade", "search").Contains($Command)) {
        if ($Skin -like "mond") { $Skin = $Self.Repository }
        if ($Parameter -like "mond") { $Parameter = $Self.Repository }
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
        "list" {
            $Skins = @()
            (ToIteratable -Object $Cache.Installed) | ForEach-Object { 
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
            Config
            break
        }
        Default {
            if (Test-DevCommand) { return }
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
    # Write-Host $_
    Write-Error $_
    Write-Host $_.ScriptStackTrace
}
