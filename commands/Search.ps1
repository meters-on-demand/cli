function Search {
    param (
        [Parameter(Position = 0)]
        [string]
        $Query,
        [Parameter(Position = 1)]
        [string]
        $Property,
        [Parameter()]
        [Switch]
        $Quiet
    )

    $Config = $MetersOnDemand.Config
    $Cache = $MetersOnDemand.Cache

    if ($Config.AlwaysUpdate) {
        $Cache = Add-SkinLists -Cache $Cache | Save-Cache
    }

    $Skins = $Cache.Skins

    if (!$Query) { $Query = ".*" }
    if (!$Property) { $Property = "fullName" }
    if (!$Quiet) { Write-Host "Searching for `"$Query`"" }

    $Results = @()
    foreach ($Skin in $Skins) {
        if ($Skin.$Property -match $Query) { $Results += $Skin }
    }

    if ($Quiet) {
        return $Results
    }
    else {
        if (!$Results) { return Write-Host "No skins found." }
        Write-Host "Found $($Results.length) skins:" -ForegroundColor Green
        Format-SkinList -Skins $Results -Description
    }

}
