function Uninstall {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force,
        [Parameter()]
        [switch]
        $Quiet
    )

    $Cache = $MetersOnDemand.Cache
    $Installed = $Cache.Installed.$FullName
    if (-not $Installed) { 
        if ($Force) { return }
        throw "Skin $FullName is not installed"
    }

    $skinPath = $Cache.SkinPath
    $skinName = $Cache.SkinsByFullName.$FullName.skinname

    $removedDirectory = RemovedDirectory
    $path = "$($skinPath)\$($skinName)"
    $target = "$($removedDirectory)\$($skinName)"
    if (Test-Path -Path "$($target)") {
        Remove-Item -Path "$($target)" -Recurse -Force
    }
    Move-Item -Path "$($path)" -Destination $removedDirectory

    $Cache | Add-Installed | Save-Cache $Cache -Quiet

    # Report results
    if (!$Quiet) {
        Write-Host "Uninstalled $($FullName)"
        Write-Host "Use 'mond restore $($FullName)' to restore"
    }

    Invoke-Bang "[!RefreshApp]" -NoStart

}
