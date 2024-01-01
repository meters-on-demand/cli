function New-Config {
    return [PSCustomObject]@{
        AlwaysUpdate = $True
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

    if ($Value -match "^(true|1)$") { $Config.$Option = $True } 
    elseif ($Value -match "^(false|0)$") { $Config.$Option = $False } 
    else { $Config.$Option = $Value }

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
