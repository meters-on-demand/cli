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
        $FullName = $SkinObject.fullName
        $RootConfig = $SkinObject.skinname
    }

    $SkinInfo = [pscustomobject](Get-SkinInfo -RootConfig $RootConfig)

    $Skin = $SkinObject | Merge-Object -Source $SkinInfo -Override

    if ($Print) { Format-SkinObject $SkinObject }
    else { return $Skin }

}

function Format-SkinObject {
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [pscustomobject]
        $Skin
    )

    $Installed = $MetersOnDemand.Cache.Installed
    $FullName = $Skin.FullName

    Write-Host $Skin.Name -ForegroundColor Blue -NoNewline
    Write-Host " $($Skin.Version)" 
    Write-Host $Skin.Description

    [pscustomobject]@{ 
        CreatedAt = $Skin.CreatedAt
        Owner     = $Skin.Owner.Name
        Topics    = $Skin.Topics -join ", "
    } | Format-List

    Write-Host @"
[Rainmeter]
$(if($Skin.LoadType) { "LoadType="+$Skin.LoadType })
$(if($Skin.Load) { "Load="+$Skin.Load })
Version=$(if($Skin.Version) {$Skin.Version} else {$Installed.$FullName.TagName})

"@

}