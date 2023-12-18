function Test-DevCommand {
    if ($Command -eq "dir") { 
        Start-Process -FilePath "explorer.exe" -ArgumentList "$($Cache.SkinPath)\$($Self.Directory)"
        return $True
    }
    if ($Command -eq "cache") {
        (ToIteratable -Object $Cache) | ForEach-Object {
            Write-Host $_
        }
        return $True
    }

    if ($Self.$Command) {
        Write-Host $Self.$Command
        return $True
    }
    if ($Cache.$Command) {
        Write-Host $Cache.$Command
        return $True
    }

    if ($Command -eq "open") {
        $RootConfig = Assert-RootConfig
        $p = "$($Cache.SkinPath)\$($RootConfig)"
        if (Test-Path -Path $p) {
            Start-Process -FilePath "$($Cache.ConfigEditor)" -ArgumentList "`"$p`""
            return $True
        }
    }

    return $False

}

function Config {
    Write-Host ""
    $Self | ToIteratable | ForEach-Object { Write-Host "$($_.Name)`t $($_.Value)" }

    Write-Host ""
    Write-Host "Cache updated`t $($Cache.LastChecked)"
    Write-Host "Skins in cache`t $(($Cache.Skins | ToIteratable | Measure-Object).Count)"
    
    Write-Host ""
    Write-Host "SkinPath`t $($Cache.SkinPath)" 
    Write-Host "SettingsPath`t $($Cache.SettingsPath)" 
    Write-Host "ProgramPath`t $($Cache.ProgramPath)" 
    Write-Host "ConfigEditor`t $($Cache.ConfigEditor)" 

    return ""
}

function New-Skin {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SkinName
    )

    $ConfigPath = "$($Cache.SkinPath)\$($SkinName)"
    $ResourcesPath = "$($ConfigPath)\@Resources"

    if (Test-Path -Path $ConfigPath) {
        throw "Skin already exists."
    }

    New-Item -ItemType Directory -Path $ConfigPath
    New-Item -ItemType Directory -Path $ResourcesPath

    # Create Mond.inc
    @"
[MonD]
Author=
PreviewImage=
ProfilePicture=
Description=

SkinName=$($SkinName)
LoadType=Skin
Load=$($SkinName)\$($SkinName).ini
Version=v1.0.0
HeaderImage=
"@ | Out-File -FilePath "$($ResourcesPath)\Mond.inc"

    # Create the variables file
    @"
[Variables]

"@ | Out-File -FilePath "$($ResourcesPath)\Variables.inc"

    # Create the skin
    @"
[Rainmeter]
DefaultUpdateDivider=-1
@IncludeVariables=#@#Variables.inc

[Metadata]
Name=$($SkinName)
Author=
Information=
Version=1.0.0
License=Creative Commons Attribution-Non-Commercial-Share Alike 3.0

[Variables]
Scale=1

[ummy]
Meter=Image

"@ | Out-File -FilePath "$($ConfigPath)\$($SkinName).ini"

    # Open the created skin in the default config editor 
    Start-Process -FilePath "$($Cache.ConfigEditor)" -ArgumentList "$ConfigPath"

}

function Refresh {
    $Cache = Update-Cache
    Start-Process -FilePath "$($Cache.ProgramPath)" -ArgumentList "[!ActivateConfig `"$($Installer.SkinName)`"]"
}

function New-Lock {
    param (
        [Parameter(Mandatory)]
        [string]
        $RootConfig
    )

    $SkinPath = $Cache.SkinPath
    $RainmeterDirectory = $Cache.RainmeterDirectory

    $plugins = Get-Plugins -RootConfig $RootConfig

    $outputFile = "$($SkinPath)\$($RootConfig)\.lock.inc"

    $output = "[Plugins]"

    foreach ($plugin in $plugins.Keys) {
        $latest = Get-LatestPlugin -Plugin $plugin
        if ($latest) {
            $output += "`n$($plugin)=$($latest.Version)"
        }
    }

    $output | Out-File -FilePath $outputFile

}

function Assert-RootConfig {
    if ($Parameter -and !$Skin) {
        $Skin = $Parameter
    }

    $Cache = Update-Cache
    $SkinPath = $Cache.SkinPath

    $workingParent = Split-Path -Path $pwd
    if (("$workingParent" -notlike "$($SkinPath)*") -and (!$Skin)) {
        throw "You must be in '$($SkinPath)\<config>' to use package without specifying the -Skin parameter!"
    }
    
    $workingName = Split-Path -Path $pwd -Leaf
    $RootConfig = $workingName
    if ($Skin) { $RootConfig = $Skin }

    return $RootConfig
}

function Limit-PowerShellVersion {

    $PowerShellVersion = $PSVersionTable.PSVersion
    if ($PowerShellVersion.Major -lt 5) {
        Write-Warning "`nYou are running PowerShell $($PowerShellVersion) which might have issues packaging skins. PowerShell 7 is recommended.`n"
    }

}
