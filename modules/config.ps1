function New-Config {
    return [PSCustomObject]@{
        AlwaysUpdate   = $True
        Load           = $True
        LoadPreference = "skin"
        LoadEither     = $False
        AskAlias       = $True
    }
}

function Get-Config {
    if (Test-Path -Path $MetersOnDemand.ConfigFile) {
        return Read-Json -Path $MetersOnDemand.ConfigFile
    }
    else {
        throw "Config file does not exist."
    }
}

function Test-ConfigOption {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Option
    )
    if ($null -eq (New-Config).$Option) { return $False } else { return $True }
}

function Write-ConfigOption {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Option
    )
    if (!(Test-ConfigOption $Option)) { throw "$($Option) is not a mond setting" }
    return $MetersOnDemand.Config.$Option
}

function Set-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Option,
        [Parameter(Mandatory, Position = 1)]
        [string]
        $Value,
        [Parameter()]
        [switch]
        $Quiet
    )

    if ($Option -like "") { throw "Cannot set configuration option '' (empty string)" }
    if (!(Test-ConfigOption $Option)) { throw "$($Option) is not a mond configuration setting" }

    $Config = $MetersOnDemand.Config
    $v
    switch ($Option) {
        "LoadType" {
            if ($Value -in @("skin", "layout")) { Break }
            throw "Accepted values: @(`"Skin`", `"Layout`")" 
        }
        Default {
            switch -regex ($Value) {
                '^(true|1)$' { $v = $True ; Break }
                '^(false|0)$' { $v = $False ; Break }
                Default { $v = $Value }
            }
        }
    }
    $Config.$Option = $v

    Save-Config -Config $Config -Quiet:$Quiet
}

function Save-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Config,
        [Parameter()]
        [switch]
        $Quiet
    )
    $MetersOnDemand.Config = $Config
    Out-Json -Quiet:$Quiet -Object $Config -Path $MetersOnDemand.ConfigFile
}
