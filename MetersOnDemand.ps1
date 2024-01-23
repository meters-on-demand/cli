[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]
    $Command = "help",
    [Parameter()]
    [switch]
    $Quiet
)
DynamicParam {

    . .\parseParams.ps1

    $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

    function Add-Param {
        param (
            [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
            [Alias("Name")]
            [string]
            $ParameterName,
            [Parameter(Mandatory, Position = 1)]
            [type]
            $Type,
            [Parameter(Mandatory, Position = 2)]
            [System.Collections.ObjectModel.Collection[System.Attribute]]
            $Attributes
        )
        $paramDictionary.Add($ParameterName, (Get-Parameter $ParameterName $Type $Attributes))
    }

    switch ($Command) {
        "help" {
            $Set = 'Help'
            Add-Param -Name 'Topic' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            break
        }
        "update" {
            $Set = 'Update'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            break
        }
        "install" {
            $Set = 'Install'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Force' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        "info" {
            $Set = 'Info'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Raw' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        "list" {
            $Set = 'List'
            Add-Param -Name 'Unmanaged' -Type "switch" -Attributes (Get-Attributes $Set)
            break 
        }
        "upgrade" {
            $Set = 'Upgrade'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Force' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        "uninstall" {
            $Set = 'Uninstall'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Force' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        "restore" {
            $Set = 'Restore'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Force' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        "init" {
            $Set = 'Init'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            break
        }
        "lock" {
            $Set = 'Lock'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            break
        }
        "package" {
            $Set = 'Package'
            
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Exclude' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'Author' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MinimumRainmeter' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'VariableFiles' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'Load' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MinimumWindows' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'HeaderImage' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MergeSkins' -Type "switch" -Attributes (Get-Attributes $Set)

            $OutPathAttributes = Get-Attributes $Set
            $OutPathAttributes.Add([System.Management.Automation.AliasAttribute]::new("o"))
            Add-Param -Name 'OutPath' -Type "String" -Attributes $OutPathAttributes

            $OutFileAttributes = Get-Attributes $Set
            $OutFileAttributes.Add([System.Management.Automation.AliasAttribute]::new("name"))
            Add-Param -Name 'OutFile' -Type "String" -Attributes $OutFileAttributes

            $OutDirectoryAttributes = Get-Attributes $Set
            $OutDirectoryAttributes.Add([System.Management.Automation.AliasAttribute]::new("OutDir", "Directory", "d"))
            Add-Param -Name 'OutFile' -Type "String" -Attributes $OutDirectoryAttributes
            
            $VersionAttributes = Get-Attributes $Set
            $VersionAttributes.Add([System.Management.Automation.AliasAttribute]::new("Version", "v"))
            Add-Param -Name 'PackageVersion' -Type "String" -Attributes $VersionAttributes
            
            $LoadTypeAttributes = Get-Attributes $Set
            $LoadTypeAttributes.Add([System.Management.Automation.ValidateEnumeratedArgumentsAttribute]::new(@("Skin", "Layout")))
            Add-Param -Name 'LoadType' -Type "String" -Attributes $VersionAttributes

            break
        }
        "search" {
            $Set = 'Search'
            Add-Param -Name 'Query' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'Property' -Type "String" -Attributes (Get-Attributes $Set)
            break
        }
        "config" {
            $Set = 'Config'
            Add-Param -Name 'Option' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            Add-Param -Name 'Value' -Type "String" -Attributes (Get-Attributes $Set $False 2)
            break
        }
        "bang" {
            $Set = 'Bang'
            Add-Param -Name 'Bang' -Type "String" -Attributes (Get-Attributes $Set $True 1)
            Add-Param -Name 'StartRainmeter' -Type "switch" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'StopRainmeter' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        Default {
            break
        }
    }
    return $paramDictionary
}
begin {
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
                Skins = "http://localhost:8000/v1/skins"
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

            $MetersOnDemand.LogFile = "$($RootConfigPath)\$($MetersOnDemand.LogFile)"

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
                }) | Add-SkinLists -Fallback | Save-Cache -Path "$($RootConfigPath)\cache.json" -Quiet

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

}
process {
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
        }

        switch ($Command) {
            "update" {
                if ($PSBoundParameters.Skin) {
                    Write-Host "Use '" -NoNewline -ForegroundColor Gray
                    Write-Host "mond upgrade $($PSBoundParameters.Skin)" -ForegroundColor White -NoNewline
                    Write-Host "' to upgrade a skin."
                    return
                }
                Get-Cache | Add-SkinLists | Save-Cache -Quiet
                Write-Host "Cache updated!"
                break
            }
            "install" {
                Install -FullName $PSBoundParameters.Skin -Force:$Force -FirstMatch:$True
                break
            }
            "info" {
                Info -Name $PSBoundParameters.Skin -Print:(!$PSBoundParameters.Raw)
                break
            }
            "list" {
                $Skins = @()
                $Unknown = @()
                (ToIteratable -Object $MetersOnDemand.Cache.Installed) | ForEach-Object {
                    $Skin = Get-SkinObject -FullName $_.name -Quiet
                    if ($Skin) { $Skins += Get-SkinObject -FullName $_.name -Quiet }
                    else { $Unknown += @{fullName = $_.Name; version = $_.value } } 
                }
                Format-SkinList -Skins $Skins
                if (!$PSBoundParameters.Unmanaged) { break }
                Write-Host "Unmanaged skins: " -BackgroundColor Yellow -NoNewline
                Write-Host ""
                Format-SkinList -Skins $Unknown
                break 
            }
            "upgrade" {
                Upgrade -FullName $PSBoundParameters.Skin -Force:$PSBoundParameters.Force
                break
            }
            "uninstall" {
                Uninstall -FullName $PSBoundParameters.Skin -Force:$PSBoundParameters.Force
                break
            }
            "restore" {
                Restore -FullName $PSBoundParameters.Skin -Force:$PSBoundParameters.Force
                break
            }
            "init" {
                New-Skin -SkinName $PSBoundParameters.Skin
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
                Search -Query $PSBoundParameters.Query -Property $PSBoundParameters.Property
                break
            }
            "config" {
                $Option = $PSBoundParameters.Option
                $Value = $PSBoundParameters.Value
                if ($Option -and $Value) {
                    return Set-Config $Option $Value
                }
                if ($Option) {
                    return Write-ConfigOption $Option
                }
                Write-FormattedConfig
                break
            }
            "bang" {
                return Invoke-Bang -Bang $PSBoundParameters.Bang -StartRainmeter:($PSBoundParameters.StartRainmeter) -StopRainmeter:($PSBoundParameters.StopRainmeter)
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
}