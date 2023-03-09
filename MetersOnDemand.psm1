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
        $Query,
        [Parameter()]
        [switch]
        $Force
    )

    & "$($PSScriptRoot)\MetersOnDemand.ps1" `
        -Command $Command `
        -Parameter $Parameter `
        -Version:$Version `
        -Force:$Force `
        -Skin $Skin `
        -Query $Query

}

Export-ModuleMember -Function MetersOnDemand -Alias mond
