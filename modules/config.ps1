function Get-Config {
    if (Test-Path -Path $MetersOnDemand.ConfigFile) {
        return Get-Content -Path $MetersOnDemand.ConfigFile | ConvertFrom-Json
    }
    else {
        throw "Config file does not exist."
    }
}

function Write-ConfigOption {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Option
    )

    $Config = $MetersOnDemand.Config
    $Value = $Config.$Option
    if ($null -eq $Value) { throw "$($Option) is not a mond setting" }
    Write-Host "$($Option) = $($Value)"

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

    $Config = $MetersOnDemand.Config
    if ($null -eq $Config.$Option) { throw "$($Option) is not a mond configuration setting" }

    if ($Value -match "^(true|1)$") { $Config.$Option = $True } 
    elseif ($Value -match "^(false|0)$") { $Config.$Option = $False } 
    else { $Config.$Option = $Value }

    Write-Host $Config
    Save-Config -Config $Config -Quiet
    if (!$Quiet) { return $Config }

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
    $Config | ConvertTo-Json -Depth 4 | Out-File -FilePath $MetersOnDemand.ConfigFile
    if (!$Quiet) {
        return $Config
    }
}
