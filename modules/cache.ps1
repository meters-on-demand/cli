function New-Cache {
    $Cache = [PSCustomObject]@{
        Skins      = [pscustomobject]@{ };
        Installed  = [pscustomobject]@{ };
        Updateable = [pscustomobject]@{ };
    }
    return $Cache
}

function Get-Cache {
    if (!(Test-Path -Path $cacheFile)) {
        throw "Cache doesn't exist"
    }
    $Cache = Get-Content -Path $cacheFile | ConvertFrom-Json
    return $Cache
}

function Update-Cache {
    param (
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]
        $Cache,
        [Parameter()]
        [switch]
        $SkipInstalled,
        [Parameter()]
        [switch]
        $Force
    )
    if ($Cache -and !$Force) { return $Cache }

    if (!$Cache) {
        $Cache = Get-Cache
    }
    
    $CurrentDate = Get-Date -Format "MM-dd-yy"
    if (!$Force -and ($Cache.LastChecked -eq $CurrentDate)) {
        if (!$SkipInstalled) { $Cache = Get-InstalledSkins -Cache $Cache }
        return $Cache
    }

    $response = $false
    try {
        $response = Get-Request $Api.Endpoints.Skins
    }
    catch {
        Write-Exception $_
        Write-Exception "Couldn't reach API, using cache..."
    }
    if (!$response) {
        if (!$SkipInstalled) { $Cache = Get-InstalledSkins -Cache $Cache }
        return $Cache
    }

    $SkinsArray = $response.Content | ConvertFrom-Json
    # PSCustomObject bullshit
    $Skins = [PSCustomObject]@{ }
    $SkinsArray | % {
        $Skins | Add-Member -MemberType NoteProperty -Name "$($_.full_name)" -Value $_
    }

    $Cache | Add-Member -MemberType NoteProperty -Name 'Skins' -Value $Skins -Force
    $Cache | Add-Member -MemberType NoteProperty -Name 'LastChecked' -Value $CurrentDate -Force

    if (-not $Cache.Installed) { $Cache | Add-Member -MemberType NoteProperty -Name 'Installed' -Value ([PSCustomObject] @{ }) -Force }
    if (-not $Cache.Updateable) { $Cache | Add-Member -MemberType NoteProperty -Name 'Updateable' -Value ([PSCustomObject] @{ }) -Force }

    $Cache = Get-InstalledSkins -Cache $Cache

    return Save-Cache $Cache
}

function Get-InstalledSkins {
    param (
        [Parameter()]
        [pscustomobject]
        $Cache
    )

    if (!$Cache) { $Cache = Update-Cache }

    $Skins = $Cache.Skins
    $SkinPath = $Cache.SkinPath
    $Installed = $Cache.Installed
    $Updateable = [PSCustomObject]@{ }

    if (!(Test-Path -Path $SkinPath)) {
        throw "SkinPath ($SkinPath) does not exist"
    }

    $NewInstalled = ([PSCustomObject] @{ })
    $skinFolders = Get-ChildItem -Path "$($SkinPath)" -Directory 
    $IteratableSkins = ToIteratable -Object $Skins
    foreach ($skinFolder in $skinFolders) {
        foreach ($Entry in $IteratableSkins) {
            $Skin = $Entry.Value
            if ($Skin.skin_name -notlike $skinFolder.name) { continue }
            $full_name = $Skin.full_name
            $existing = $Installed.$full_name
            $latest = $Skin.latest_release.tag_name
            if ($existing) {
                $NewInstalled | Add-Member -MemberType NoteProperty -Name "$full_name" -Value $existing
                if ($existing -ne $latest) { 
                    $Updateable | Add-Member -MemberType NoteProperty -Name "$full_name" -Value $latest
                }
            }
            else { 
                $NewInstalled | Add-Member -MemberType NoteProperty -Name "$full_name" -Value $latest
            }
        }
    }

    $Cache | Add-Member -MemberType noteproperty -Name 'Installed' -Value $NewInstalled -Force
    $Cache | Add-Member -MemberType noteproperty -Name 'Updateable' -Value $Updateable -Force

    return $Cache

}

function Save-Cache {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [PSCustomObject]
        $Cache
    )
    $Cache | ConvertTo-Json -Depth 4 | Out-File -FilePath $cacheFile
    return $Cache
}
