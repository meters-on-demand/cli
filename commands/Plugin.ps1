function Plugin {
    [CmdletBinding(DefaultParameterSetName = "AsSkin")]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = "AsSkin")]
        [string]
        $FullName,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "AsPlugin")]
        [string]
        $PluginName,
        [Parameter()]
        [switch]
        $Force,
        [Parameter()]
        [Switch]
        $FirstMatch
    )

    if ($FullName) { return Install -FullName $FullName -Force:$Force -FirstMatch:$FirstMatch }

    $isBuiltIn = Test-BuiltIn -Plugin $PluginName

    if ($isBuiltIn) { return }
    if (Get-LatestPlugin -Plugin $PluginName -Quiet) { return }

    Write-Warning "Skin uses plugin '$($PluginName)' which is not installed. Install it or the skin might not work properly"

}
