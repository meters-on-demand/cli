[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]
    $Command,
    [Parameter()]
    [switch]
    $Quiet
)
DynamicParam {
    $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

    function Get-Attributes {
        param (
            [Parameter(Position = 0, ValueFromPipeline)]
            [string]
            $ParameterSetName,
            [Parameter(Position = 1)]
            [System.Boolean]
            $Mandatory,
            [Parameter(Position = 2)]
            [int]
            $Position,
            [Parameter()]
            [String[]]
            $Alias,
            [Parameter()]
            [String[]]
            $Enum
        )
        $Attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $a = [System.Management.Automation.ParameterAttribute]@{ }
        if ($ParameterSetName) { $a.ParameterSetName = $ParameterSetName }
        if ($Mandatory) { $a.Mandatory = $Mandatory }
        if ($Position) { $a.Position = $Position }
        $Attributes.Add($a)
        if ($Alias) {
            $Attributes.Add([System.Management.Automation.AliasAttribute]::new($Alias))
        }
        if ($Enum) {
            $Attributes.Add([System.Management.Automation.ValidateSetAttribute]::new($Enum))
        }
        return $Attributes
    }
    
    function Get-Parameter {
        param (
            [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
            [string]
            $ParameterName,
            [Parameter(Mandatory, Position = 1)]
            [type]
            $Type,
            [Parameter(Mandatory, Position = 2)]
            [System.Collections.ObjectModel.Collection[System.Attribute]]
            $Attributes
        )
        return [System.Management.Automation.RuntimeDefinedParameter]::new(
            $ParameterName, $Type, $Attributes
        )
    }

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
        "open" {
            $Set = 'Open'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $True 1)
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
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            break
        }
        "package" {
            $Set = 'Package'
            Add-Param -Name 'Skin' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            Add-Param -Name 'Exclude' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'Author' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MinimumRainmeter' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'VariableFiles' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'Load' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MinimumWindows' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'HeaderImage' -Type "String" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'MergeSkins' -Type "switch" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'OutPath' -Type "String" -Attributes (Get-Attributes $Set -Alias @("o"))
            Add-Param -Name 'OutFile' -Type "String" -Attributes (Get-Attributes $Set -Alias @("Name"))
            Add-Param -Name 'OutDirectory' -Type "String" -Attributes (Get-Attributes $Set -Alias @("OutDir", "Directory", "d"))
            Add-Param -Name 'PackageVersion' -Type "String" -Attributes (Get-Attributes $Set -Alias @("Version"))
            Add-Param -Name 'LoadType' -Type "String" -Attributes (Get-Attributes $Set -Enum @("Skin", "Layout"))
            break
        }
        "search" {
            $Set = 'Search'
            Add-Param -Name 'Query' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            Add-Param -Name 'Property' -Type "String" -Attributes (Get-Attributes $Set $False 2)
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
            Add-Param -Name 'Bang' -Type "String" -Attributes (Get-Attributes $Set $False 1)
            Add-Param -Name 'StartRainmeter' -Type "switch" -Attributes (Get-Attributes $Set)
            Add-Param -Name 'StopRainmeter' -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
        Default {
            $Set = "NoCommand"
            Add-Param -Name "Version" -Type "switch" -Attributes (Get-Attributes $Set)
            break
        }
    }
    return $paramDictionary
}
begin {
    # Globals
    $MetersOnDemand = [PSCustomObject]@{ 
        Version       = "v1.9.9"
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
                Skins = "https://api.rainmeter.skin/v1/skins"
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

    function Update-Status {
        param (
            [Parameter()]
            [String]
            $Status
        )
        $Meter = "MeterStatus"
        Invoke-Bang "[!SetOption $Meter Text `"$Status`"][!UpdateMeter $Meter][!Redraw]"
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
                Update-Status "Merging existing user settings"
                Write-Host "Merging existing user settings"
                $Config = Read-Json -Path $UserConfig | Merge-Object -Source $Config
            }
            Out-Json -Object $Config -Path $TempConfig

            # Clear the InstallPath
            Update-Status "Removing current version"
            Write-Host "Removing current version"
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

            Update-Status "Querying the API, this might take a while..."
            Write-Host "Creating the cache"
            Write-Host "Querying the API"
            New-Cache | Merge-Object -Override -Source ([PSCustomObject]@{
                    SkinPath           = $SkinPath
                    SettingsPath       = $SettingsPath
                    ProgramPath        = $ProgramPath
                    RainmeterDirectory = $RainmeterDirectory
                    ConfigEditor       = $ConfigEditor
                }) | Add-SkinLists -Fallback | Save-Cache -Path "$($RootConfigPath)\cache.json" -Quiet

            Update-Status "Copying script files"
            Write-Host "Copying script files from '$RootConfigPath' to '$InstallPath'"
            New-Item -ItemType Directory -Path "$($InstallPath)"
            # Copy directories
            Copy-Item -Path "$($RootConfigPath)\commands" -Destination "$($InstallPath)" -Recurse -Force
            Copy-Item -Path "$($RootConfigPath)\modules" -Destination "$($InstallPath)" -Recurse -Force
            # Copy loose files
            Get-ChildItem -Path "$($RootConfigPath)\*" -File -Include "*.ps1", "*.bat", "*.json" | Copy-Item -Destination "$($InstallPath)"

            Update-Status "Adding mond to PATH"
            Write-Host "Adding '$InstallPath' to user environment PATH"
            Set-PathVariable -AddPath $InstallPath

            Update-Status "Install complete!"
            Write-Host "Successfully installed Meters on Demand $($MetersOnDemand.Version)!"

            Invoke-Bang "[!Delay 500][!About][!DeactivateConfig]"
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

        # Commands that do not need the cache or config
        if ($Command -eq "version") { return Version }

        # Read the config
        $MetersOnDemand.Config = Get-Config

        # Commands that don't need the cache
        if ($Command -eq "help") { return Help $PSBoundParameters.Topic }

        # Read the cache
        $MetersOnDemand.Cache = Get-Cache

        if ($isDotSourced) { return }

        # Mond skin alias
        if (@("install", "upgrade", "search").Contains($Command)) {
            if ($PSBoundParameters.Skin -like "mond") { $PSBoundParameters.Skin = $MetersOnDemand.FullName }
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
            "alias" {
                Set-MondAlias
                break
            }
            "install" {
                Install -FullName $PSBoundParameters.Skin -Force:$PSBoundParameters.Force -FirstMatch:$True
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
                $RootConfig = Assert-RootConfig $PSBoundParameters.Skin
                New-Lock -RootConfig $RootConfig
            }
            "open" {
                $RootConfig = Assert-RootConfig $PSBoundParameters.Skin
                Open-Skin $RootConfig
                break
            }
            "package" {
                Limit-PowerShellVersion
                $RootConfig = Assert-RootConfig $PSBoundParameters.Skin
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
                if ($PSBoundParameters.Version) { return Version }
                if ($isDotSourced) { return }
                if ($Command) { return Test-DevCommand }
                return Help $PSBoundParameters.Topic
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