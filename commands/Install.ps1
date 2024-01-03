function Install {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force,
        [Parameter()]
        [Switch]
        $FirstMatch
    )

    if ($FullName -match "^http|\.git$") { return Install-FromGit -Uri $FullName -Force:$Force }

    try {
        $Skin = Get-SkinObject -FullName $FullName
    }
    catch {
        if (!$FirstMatch) { throw $_ }
    }

    if (!$Skin -and $FirstMatch) {
        $Matched = Search -Query $FullName -Quiet
        if ($Matched.Length -gt 1) {
            # TODO: List results
            throw "Too many results, use a more specific query"
        }
        if ($Matched.Length -eq 0) { throw "No results" }
        $FullName = $Matched[0].full_name
    }

    Test-Installed -FullName $FullName -Force:$Force
    Write-InstallCache -FullName $FullName

    Download -FullName $FullName
    Start-Process -FilePath $MetersOnDemand.SkinFile

}

function Test-Installed {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Force
    )

    if ($Force) { return }

    $Cache = $MetersOnDemand.Cache
    $Installed = $Cache.Installed

    $installedVersion = $Installed.$FullName
    if ($installedVersion -and (-not $Force)) {
        throw "$($FullName) is already installed. Use -Force to reinstall."
    }

}

function Write-InstallCache {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [string]
        $Version
    )

    $Cache = $MetersOnDemand.Cache
    $Installed = $Cache.Installed

    if (!$Version) {
        $Skin = Get-SkinObject -FullName $FullName
        $Version = $Skin.latest_release.tag_name
    }

    if ($installedVersion -ne $Version) {
        $Installed | Add-Member -MemberType NoteProperty -Name "$FullName" -Value $Version -Force
        $Cache | Add-Member -MemberType NoteProperty -Name "Installed" -Value $Installed -Force
        $Cache.Updateable.psobject.properties.Remove($FullName)
        Save-Cache $Cache -Quiet
    }

}

function Install-FromGit {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Uri,
        [Parameter()]
        [switch]
        $Force
    )

    if (!(Get-Command git)) { 
        Write-Host "Can't install from remote source without git"
        Write-Host "Install git with " -NoNewline
        Write-Host "'winget install Git.Git'" -ForegroundColor White
        return
    }

    # Extract information from the uri
    $Uri = $Uri -replace "\/$", ""
    $FullName = $Uri -replace '^.*\/(.*?\/.*?)(?:\.git)?$', '$1'
    $RootConfig = $FullName.Split('/')[1]
    
    $temp = Clear-Temp
    $origin = $pwd
    Set-Location -Path "$($temp)"
    

    try {
        Test-Installed -FullName $FullName -Force:$Force
        Write-Host "Cloning '$($FullName)'"
        git clone $Uri . --quiet
        Write-Host "Fetching tags..."
        git fetch --tags --quiet
        $tagName = git describe --tags --abbrev=0
        if ($tagName) {
            Write-Host "Installing latest tag '$($tagName)'"
            git reset "$tagName" --hard --quiet
        }
        else {
            $tagName = "latest"
            Write-Warning "Skin has no releases or git tags, installing the latest commit instead... It might be unstable."
        }
        Install-Silently -RootConfig $RootConfig -Path "$temp"
    }
    catch {
        throw $_
    }
    finally {
        Clear-Temp -Quiet
        Set-Location -Path "$($origin)"
    }
}

function Install-Silently {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $RootConfig,
        [Parameter()]
        [string]
        $Path,
        [Parameter()]
        [switch]
        $Quiet
    )

    $Cache = $MetersOnDemand.Cache
    $SkinPath = $Cache.SkinPath

    if (!$Path) { $Path = "$($SkinPath)\$($MetersOnDemand.TempDirectory)" }
    $Destination = "$($SkinPath)\$($RootConfig)"
    if (Test-Path -Path $Destination) { Remove-Item -Path $Destination -Force -Recurse }
    Copy-Item -Recurse -Path "$Path" -Destination $Destination
    Get-Plugins -RootConfig "$RootConfig" | ForEach-Object { Plugin -PluginName "$($_)" }

    if (!$Quiet) {
        Write-Host "Installed $($RootConfig)!" -ForegroundColor Green
    }

}
