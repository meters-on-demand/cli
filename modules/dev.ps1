function Test-DevCommand {
    $Cache = $MetersOnDemand.Cache

    switch ($Command) {
        "dir" { 
            Start-Process -FilePath "explorer.exe" -ArgumentList "$($Cache.SkinPath)\$($MetersOnDemand.Directory)"
            return 
        }
        "cache" {
            return $Cache
        }
        "open" {
            $RootConfig = Assert-RootConfig
            return Open-Skin $RootConfig
        }
        Default {}
    }

    if ($MetersOnDemand.$Command) {
        return $MetersOnDemand.$Command
    }
    if ($Cache.$Command) {
        return $Cache.$Command
    }

    Write-Host "$Command" -ForegroundColor Red -NoNewline
    Write-Host " is not a command! Use" -NoNewline 
    Write-Host " MonD help " -ForegroundColor Blue -NoNewline
    Write-Host "to see available commands!"

}

function Write-FormattedConfig {
    $Config = $MetersOnDemand.Config
    $Cache = $MetersOnDemand.Cache

    # Get counts from cache
    $skinsCount = ($Cache.Skins | Measure-Object).Count
    $installedCount = ($Cache.Installed | ToIteratable | Measure-Object).Count

    # Format cache values
    $Cache.Skins = "@(@{ full_name = `"meters-on-demand/cli`", skin_name = `"Meters on Demand`", ... }, $($skinsCount - 1) more items... )"
    $Cache.SkinsByFullName = "@{ `"meters-on-demand/cli`": @{ ... }, $($skinsCount - 1) more items... }"
    $Cache.SkinsBySkinName = "@{ `"Meters on Demand`": @{ ... }, $($skinsCount - 1) more items... }"
    $Cache.Installed = "@{ `"meters-on-demand/cli`": `"$($MetersOnDemand.Version)`", $($installedCount - 1) more items... }"
    if (($Cache.Updateable | ToIteratable | Measure-Object).Count -eq 0) { $Cache.UpdateAble = "@{ }" }

    # Mark previously written values
    $MetersOnDemand.Config = "@{ ... } (see above)"
    $MetersOnDemand.Cache = "@{ ... } (see above)"

    # Write everything
    Write-Host "Configuration settings (`$MetersOnDemand.Config)" -ForegroundColor Blue -NoNewline
    $Config | Format-List
    Write-Host "Cache (`$MetersOnDemand.Cache)" -ForegroundColor Blue -NoNewline
    $Cache | Format-List
    Write-Host "Self (`$MetersOnDemand)" -ForegroundColor Blue -NoNewline
    $MetersOnDemand | Format-List
}

function New-Skin {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SkinName
    )

    $Cache = $MetersOnDemand.Cache
    $ConfigPath = "$($Cache.SkinPath)\$($SkinName)"
    $ResourcesPath = "$($ConfigPath)\@Resources"

    if (Test-Path -Path $ConfigPath) {
        throw "Skin already exists."
    }

    New-Item -ItemType Directory -Path $ConfigPath | Out-Null 
    New-Item -ItemType Directory -Path $ResourcesPath | Out-Null

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

    Write-Host "Created $($SkinName)" -NoNewline

    Open-Skin -SkinName $SkinName

}

function Open-Skin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $SkinName
    )

    $ConfigPath = "$($Cache.SkinPath)\$($SkinName)"
    
    if (!(Test-Path -Path $ConfigPath)) {
        throw "Specified skin does not exist"
    }
    
    $ConfigEditor = $Cache.ConfigEditor
    if ($ConfigEditor -like "*notepad.exe") {
        $ConfigEditor = "explorer.exe"
    }

    Start-Process -FilePath "$($ConfigEditor)" -ArgumentList "`"$ConfigPath`""

}

function Refresh {
    Invoke-Bang "[!ActivateConfig `"$($MetersOnDemand.SkinName)`"]" -Start
}

function New-Lock {
    param (
        [Parameter(Mandatory)]
        [string]
        $RootConfig,
        [Parameter()]
        [switch]
        $Quiet
    )

    $Cache = $MetersOnDemand.Cache
    $SkinPath = $Cache.SkinPath

    $plugins = Get-Plugins -RootConfig $RootConfig

    $outputFile = "$($SkinPath)\$($RootConfig)\.lock.inc"

    $output = "[Plugins]"

    foreach ($plugin in $plugins) {
        $latest = Get-LatestPlugin -Plugin $plugin
        if ($latest) {
            $output += "`n$($plugin)=$($latest.Version)"
        }
    }

    $output | Out-File -FilePath $outputFile
    if (!$Quiet) { Write-Host $output }

}

function Assert-RootConfig {
    if ($Parameter -and !$Skin) {
        $Skin = $Parameter
    }

    $Cache = $MetersOnDemand.Cache
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
