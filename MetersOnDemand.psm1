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
        [Parameter(Position = 2)]
        [string]
        $Option,
        [Parameter()]
        [string]
        $Skin,
        [Parameter()]
        [string]
        $Query,
        [Parameter()]
        [string]
        $Property,
        [Alias("v")]
        [Parameter()]
        [switch]
        $Version,
        [Parameter()]
        [switch]
        $Force
    )

    & "$($PSScriptRoot)\MetersOnDemand.ps1" `
        -Command $Command `
        -Parameter $Parameter `
        -Option $Option `
        -Version:$Version `
        -Force:$Force `
        -Skin $Skin `
        -Query $Query `
        -Property $Property 

}

Export-ModuleMember -Function MetersOnDemand -Alias mond
