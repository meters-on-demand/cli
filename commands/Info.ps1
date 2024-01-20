function Info {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,
        [Parameter()]
        [switch]
        $Print
    )

    $IsFullName = $Name.Contains("/")

    $Cache = $MetersOnDemand.Cache

    $RootConfig = $False
    $FullName = $False
    $SkinObject = $False
    if ($IsFullName) {
        $SkinObject = $Cache.SkinsByFullName.$Name
    }
    else {
        $SkinObject = $Cache.SkinsBySkinName.$Name
    }

    if (!$SkinObject) {
        # Try finding by rootconfig
        # Try finding by searching the cache
        throw "Couldn't find skin $($Name)"
        # Handle unmanaged skin
        # $FullName = $Rootconfig
    }
    else {
        $FullName = $SkinObject.full_name
        $RootConfig = $SkinObject.skin_name
    }

    $SkinInfo = [pscustomobject](Get-SkinInfo -RootConfig $RootConfig)

    $Skin = $SkinObject | Merge-Object -Source $SkinInfo -Override

    if ($Print) { Format-SkinObject $SkinObject }
    else { return $Skin }

}

function Format-SkinObjec {
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [pscustomobject]
        $Skin
    )

    Write-Host $Skin

}