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

    Write-Host "Skin requires plugin $($PluginName), install it or the skin might not work properly"

}
