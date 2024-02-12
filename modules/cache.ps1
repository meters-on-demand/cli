function New-Cache {
    return [PSCustomObject]@{
        Skins      = [pscustomobject]@{ };
        Installed  = [pscustomobject]@{ };
        Updateable = [pscustomobject]@{ };
    }
}

function Add-SkinLists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Cache,
        [Parameter()]
        [switch]
        $Fallback,
        [Parameter()]
        [switch]
        $Break
    )

    $CurrentDate = Get-Date -Format "MM-dd-yy"
    $Cache | Add-Member -MemberType NoteProperty -Name "LastChecked" -Value $CurrentDate -Force

    if ($Fallback) { $Break = $True }
    try {
        $Skins = Get-SkinList -Cache $Cache -Break:$Break
    }
    catch {
        if (!$Fallback) { throw $_ }
        $Skins = @()
        $Cache | Add-Member -MemberType NoteProperty -Name "Skins" -Value $Skins -Force
        return Add-Installed $Cache
    }

    $Cache | Add-Member -MemberType NoteProperty -Name "Skins" -Value $Skins -Force
    $Cache | Add-Member -MemberType NoteProperty -Name "SkinsBySkinName" -Value (Get-SkinsBySkinName -Skins $Skins) -Force
    $Cache | Add-Member -MemberType NoteProperty -Name "SkinsByFullName" -Value (Get-SkinsByFullName -Skins $Skins) -Force

    $Cache = Add-Installed $Cache
    return $Cache
}

function Add-Installed {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Cache
    )
    $Installed = Get-InstalledSkins -Cache $Cache
    $Cache | Add-Member -MemberType NoteProperty -Name "Installed" -Value $Installed -Force

    $Updateable = Get-UpdateableSkins -Cache $Cache
    $Cache | Add-Member -MemberType NoteProperty -Name "Updateable" -Value $Updateable -Force
    return $Cache
}

function Get-Cache {
    if (Test-Path -Path $MetersOnDemand.CacheFile) {
        return Read-Json -Path $MetersOnDemand.CacheFile
    }
    else {
        throw "Cache file does not exist."
    }
}

function Get-SkinList {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Cache,
        [Parameter()]
        [switch]
        $Quiet,
        [Parameter()]
        [switch]
        $Break
    )

    $response = $false
    try {
        $response = Get-Request $MetersOnDemand.Api.Endpoints.Skins
    }
    catch {
        if ($Break) {
            throw "Couldn't reach the API"
        }
        if (!$Quiet) {
            Write-Exception $_
            Write-Exception "Couldn't reach the API, using cache..."
        }
    }
    if (!$response) { return $Cache.Skins }

    $SkinsArray = $response.Content | ConvertFrom-Json
    return $SkinsArray
}

function Get-SkinsBySkinName {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Skins
    )

    if (!$Skins) { $Skins = $MetersOnDemand.Cache.Skins }
    $SkinsBySkinName = [PSCustomObject]@{ }
    $Skins | ForEach-Object {
        $SkinsBySkinName | Add-Member -MemberType NoteProperty -Name "$($_.skinName)" -Value $_ -Force
    }
    return $SkinsBySkinName

}

function Get-SkinsByFullName {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Skins
    )

    if (!$Skins) { $Skins = $MetersOnDemand.Cache.Skins }
    $SkinsByFullName = [PSCustomObject]@{ }
    $Skins | ForEach-Object {
        $SkinsByFullName | Add-Member -MemberType NoteProperty -Name "$($_.fullName)" -Value $_ -Force
    }
    return $SkinsByFullName

}

function Get-InstalledSkins {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Cache
    )

    $Skins = $Cache.Skins
    $SkinPath = $Cache.SkinPath
    $Installed = $Cache.Installed

    if (!(Test-Path -Path $SkinPath)) {
        throw "SkinPath ($SkinPath) does not exist"
    }

    $NewInstalled = ([PSCustomObject] @{ })
    $SkinsBySkinName = $Cache.SkinsBySkinName
    Get-ChildItem -Path "$($SkinPath)\*" -Directory | ForEach-Object {
        $RootConfig = $_.BaseName

        if (@("@", "#").Contains([string]$RootConfig[0])) { return }

        $SkinInfo = Get-SkinInfo -RootConfig $RootConfig
        $Skin = $SkinsBySkinName.$RootConfig
        if ((!$Skin) -and (!$SkinInfo)) { return }

        $fullName = $Skin.fullName
        if (!$fullName) { $fullName = $RootConfig }
        $existing = $SkinInfo.Version
        if (!$existing) { $existing = $Installed.$fullName }

        if ($existing) {
            $NewInstalled | Add-Member -MemberType NoteProperty -Name "$fullName" -Value $existing
        }
        else {
            $latest = $Skin.latestRelease.tagName
            if (!$latest) { $latest = "unknown" }
            $NewInstalled | Add-Member -MemberType NoteProperty -Name "$fullName" -Value $latest
        }
    }

    return $NewInstalled

}

function Get-UpdateableSkins {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Cache
    )

    $Updateable = [PSCustomObject]@{ }
    $SkinsByFullName = $Cache.SkinsByFullName
    $InstalledSkins = $Cache.Installed | ToIteratable

    foreach ($entry in $InstalledSkins) {
        $FullName = $entry.Name
        $installed = $entry.Value
        $latest = $SkinsByFullName.$FullName.version
        if (!$latest) { continue }
        if ($installed -ne $latest) { 
            $Updateable | Add-Member -MemberType NoteProperty -Name "$FullName" -Value $latest
        }
    }

    return $Updateable

}

function Save-Cache {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [PSCustomObject]
        $Cache,
        [Parameter()]
        [string]
        $Path,
        [Parameter()]
        [switch]
        $Quiet
    )
    $MetersOnDemand.Cache = $Cache
    if (!$Path) { $Path = $MetersOnDemand.CacheFile }
    $Cache | Out-Json -Path $Path -Quiet:$Quiet
}
