function Get-Config {
    if (Test-Path -Path $MetersOnDemand.ConfigFile) {
        return Get-Content -Path $MetersOnDemand.ConfigFile | ConvertFrom-Json
    }
    else {
        throw "Config file does not exist."
    }
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

    $Config = $MetersOnDemand.Config
    $Config | Add-Member -NotePropertyName "$Option" -NotePropertyValue "$Value" | Save-Config -Quiet
    if (!Quiet) { return $Config }

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
