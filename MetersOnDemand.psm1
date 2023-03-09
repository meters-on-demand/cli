function MetersOnDemand() {
    [Alias("mond")]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Command = "help",
        [Parameter(Position = 1)]
        [string]
        $Parameter,
        [Alias("v")]
        [Parameter()]
        [switch]
        $Version,
        [Parameter()]
        [string]
        $Skin,
        [Parameter()]
        [string]
        $Query
    )

    & "$($PSScriptRoot)\MetersOnDemand.ps1" `
        -Command $Command `
        -Parameter $Parameter `
        -Version:$Version `
        -Skin $Skin `
        -Query $Query

}

Export-ModuleMember -Function MetersOnDemand -Alias mond
