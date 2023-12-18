function Restore {
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

    $skinPath = $Cache.SkinPath
    $skinName = $Cache.Skins.$FullName.skin_name

    $removedDirectory = RemovedDirectory
    $restorePath = "$($removedDirectory)\$($skinName)"
    $restoreTarget = "$($skinPath)\$($skinName)"
    if (-not (Test-Path -Path "$($restorePath)")) {
        if ($Force) { return }
        throw "Cannot restore: $($FullName) was not found in $($Removed)."
    }
    if (Test-Path -Path "$($restoreTarget)") {
        if ($Force) {
            Remove-Item -Path "$($restoreTarget)" -Recurse -Force
        }
        else {
            throw "Cannot restore: $($FullName) is already installed. Use -Force to overwrite."
        }
    }
    Move-Item -Path "$($restorePath)" -Destination $skinPath -Force

    # Update cache
    $Cache = Get-InstalledSkins -Cache $Cache
    $Cache = Save-Cache $Cache

    # Report results
    if (!$Quiet) {
        Write-Host "Restored $($FullName)"
    }

}
