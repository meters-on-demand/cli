function Get-SkinObject {
    [CmdletBinding(DefaultParameterSetName = "FullName")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = "FullName")]
        [string]
        $FullName,
        [Parameter(Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = "RootConfig")]
        [string]
        $RootConfig,
        [Parameter()]
        [switch]
        $Quiet
    )
    $Name = if ($FullName) { $FullName } else { $RootConfig } 
    $Cache = $MetersOnDemand.Cache
    $Skin = $False
    if ($FullName) {
        $Skin = $Cache.SkinsByFullName.$FullName
    }
    else {
        $Skin = $Cache.SkinsBySkinName.$RootConfig
    }
    if ((!$Quiet) -and (!$Skin)) { throw "Couldn't find $($Name)" } 
    return $Skin
}

function Get-Request {
    param(
        [Parameter(Position = 0)]
        [string]
        $Uri
    )
    $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing
    return $response
}

function RemovedDirectory {
    $removedDirectory = "$($Cache.SkinPath)\@Backup"
    if (-not(Test-Path -Path $removedDirectory)) {
        New-Item -Path $removedDirectory -ItemType Directory
    }
    return $removedDirectory
}

function ToIteratable {
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [pscustomobject]
        $Object
    )
    $Members = $Object.psobject.Members | Where-Object membertype -like 'noteproperty'
    return $Members
}

function Get-MondInc {
    [CmdletBinding(DefaultParameterSetName = "RootConfig")]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "RootConfig")]
        [string]
        $RootConfig,
        [Parameter(Mandatory, ParameterSetName = "Path")]
        [string]
        $Path
    )
    $Cache = $MetersOnDemand.Cache
    $SkinPath = $Cache.SkinPath
    $RootConfigPath = if ($RootConfig) { "$($SkinPath)\$($RootConfig)" } else { $Path }
    if (Test-Path "$($RootConfigPath)\mond.inc") {
        return "$($RootConfigPath)\mond.inc"
    }
    if (Test-Path "$($RootConfigPath)\@Resources\mond.inc") {
        return "$($RootConfigPath)\@Resources\mond.inc"
    }
    return $False
}

function Clear-Temp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Quiet
    )
    $temp = $MetersOnDemand.TempDirectory
    if (!(Test-Path -Path "$temp")) {
        $__ = New-Item -ItemType Directory -Path $temp 
    }
    $__ = Remove-Item -Path "$temp\*" -Recurse -Force
    if (!$Quiet) { return $temp }
}

function Get-SkinInfo {
    [CmdletBinding(DefaultParameterSetName = "RootConfig")]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "RootConfig")]
        [string]
        $RootConfig,
        [Parameter(Mandatory, ParameterSetName = "FullName")]
        [string]
        $FullName,
        [Parameter(Mandatory, ParameterSetName = "Path")]
        [Parameter(ParameterSetName = "RootConfig")]
        [string]
        $Path
    )

    $Name = if ($RootConfig) { $RootConfig } else { $FullName }

    $Overrides = @{
        Author           = "$Author"
        Version          = "$PackageVersion"
        LoadType         = "$LoadType"
        Load             = "$Load"
        VariableFiles    = "$VariableFiles"
        MinimumRainmeter = "$MinimumRainmeter"
        MinimumWindows   = "$MinimumWindows"
        HeaderImage      = "$HeaderImage"
        Exclude          = "$Exclude"
    }

    $RMSKIN = @{
        SkinName         = $RootConfig
        Author           = $null
        Version          = $null
        LoadType         = $null
        Load             = $null
        VariableFiles    = $null
        MinimumRainmeter = "4.5.17"
        MinimumWindows   = "5.1"
        HeaderImage      = $null
        Exclude          = ""
        MergeSkins       = $null
    }

    if ($FullName) {
        $RootConfig = (Get-SkinObject -FullName $FullName).skinname
    }
    elseif ($Path) {
        $mondinc = Get-MondInc -Path $Path
        $RootConfig = (Split-Path -Path $Path -Leaf) 
    }

    if (!$RootConfig) { throw "Couldn't find info for $($Name)" }

    if (!$Path) { $mondinc = Get-MondInc -RootConfig $RootConfig }

    if ($mondinc) {
        Get-Content -Path $mondinc | ForEach-Object {
            $s = $_ -split "="
            $option = "$($s[0])".Trim().ToLower()
            $value = "$($s[1])".Trim()
            if ($option -in @("variablefiles", "headerimage")) {
                # TODO: Use | bruh
                $value = $value -replace "#@#\\", "$($RootConfig)\@Resources\"
                $value = $value -replace "#@#", "$($RootConfig)\@Resources\"
            }
            if ($option -in $RMSKIN.Keys) {
                $RMSKIN[$option] = $value
            }
        }
    }

    foreach ($option in $Overrides.GetEnumerator()) {
        if ($option.Value) {
            $RMSKIN[$option.Name] = $option.Value
        }
    }

    # Handle loading .ini without #ROOTCONFIG#
    if ($RMSKIN.LoadType -like "skin" -and $RMSKIN.Load -match "\.ini$") {
        $loader = $RMSKIN.Load -replace "^$($RootConfig)\\", ""
        $loader = "$($RootConfig)\$($loader)"
        $RMSKIN.Load = $loader
    }

    # Handle MergeSkins
    if ($MergeSkins) { $RMSKIN["MergeSkins"] = 1 }
    if ($RMSKIN.MergeSkins) { $RMSKIN.Remove("VariableFiles") }

    return $RMSKIN
}

function Add-RMfooter {
    param (
        [Parameter()]
        [string]
        $Target
    )

    $AsByteStream = $True
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $AsByteStream = $False
    }    

    # Yoinked from https://github.com/brianferguson/auto-rmskin-package/blob/master/.github/workflows/release.yml
    Write-Output "Writing security flags..."
    $size = [long](Get-Item $Target).length
    $size_bytes = [System.BitConverter]::GetBytes($size)
    if ($AsByteStream) {
        Add-Content -Path $Target -Value $size_bytes -AsByteStream
    }
    else {
        Add-Content -Path $Target -Value $size_bytes -Encoding Byte
    }

    $flags = [byte]0

    if ($AsByteStream) {
        Add-Content -Path $Target -Value $flags -AsByteStream
    }
    else {
        Add-Content -Path $Target -Value $flags -Encoding Byte
    }

    $rmskin = [string]"RMSKIN`0"
    Add-Content -Path $Target -Value $rmskin -NoNewLine -Encoding ASCII

    Write-Output "Renaming .zip to .rmskin..."
    Rename-Item -Path $Target -NewName ([io.path]::ChangeExtension($Target, '.rmskin'))
    $Target = $Target.Replace(".zip", ".rmskin")
}

# https://github.com/ThePoShWolf/Utilities/blob/master/Misc/Set-PathVariable.ps1
# Added |^$ to filter out empty items in $arrPath
# Removed the $Scope param and added a static [System.EnvironmentVariableTarget]::User
function Set-PathVariable {
    param (
        [string]$AddPath,
        [string]$RemovePath
    )

    $Scope = [System.EnvironmentVariableTarget]::User

    $regexPaths = @()
    if ($PSBoundParameters.Keys -contains 'AddPath') {
        $regexPaths += [regex]::Escape($AddPath)
    }
    
    if ($PSBoundParameters.Keys -contains 'RemovePath') {
        $regexPaths += [regex]::Escape($RemovePath)
    }
        
    $arrPath = [System.Environment]::GetEnvironmentVariable('PATH', $Scope) -split ';'
    foreach ($path in $regexPaths) {
        $arrPath = $arrPath | Where-Object { $_ -notMatch "^$path\\?| ^$" }
    }
    $value = ($arrPath + $addPath) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $value, $Scope)
}

function Write-Exception {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]
        $Exception,
        [Parameter()]
        [switch]
        $Breaking
    )
    if (!$RmApi) { return Write-Error $Exception }
    if ($Exception -is [System.Management.Automation.ErrorRecord]) {
        $RmApi.LogWarning($Exception.ScriptStackTrace)
    }
    $RmApi.LogError($Exception)
    if ($Breaking) {
        Invoke-Bang "[!About][!DeactivateConfig]"
        exit
    }
}

function Format-SkinList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Skins,
        [Parameter()]
        [Switch]
        $NewLine,
        [Parameter()]
        [Switch]
        $Description
    )

    $Skins | Sort-Object -Property "fullName" | ForEach-Object {
        Write-Host $_.fullName -ForegroundColor Blue -NoNewline
        $current = $_.version
        $versionColor = "Gray"
        $installed = $Cache.Installed.($_.fullName)
        $updateable = $Cache.Updateable.($_.fullName)
        if ($installed) {
            $current = $installed
            $versionColor = "Green"
        }
        Write-Host " $($current)" -ForegroundColor $versionColor -NoNewline

        if ($updateable) { Write-Host " ($($updateable) available)" -ForegroundColor Yellow }
        else { Write-Host "" }

        if ($Description) { Write-Host "$($_.description)" }
        if ($NewLine) { Write-Host "" }
    }
}

function Download {
    param (
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [string]
        $FullName,
        [Parameter()]
        [switch]
        $Quiet
    )

    $Skin = Get-SkinObject $FullName

    if (!$Quiet) {
        Write-Host "Downloading $($Skin.fullName)"
    }

    Invoke-WebRequest -Uri $Skin.latestRelease.uri -OutFile $MetersOnDemand.SkinFile

    return $MetersOnDemand.SkinFile
}

function Merge-Object {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Target,
        [Parameter(Mandatory)]
        [pscustomobject]
        $Source,
        [Parameter()]
        [switch]
        $Override
    )
    $Source | ToIteratable | ForEach-Object {
        $Key = $_.Name
        $Value = $_.Value
        if ((!$Target.$Key) -or ($Override)) {
            $Target | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        }
    }
    return $Target
}

function Out-Json {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject]
        $Object,
        [Parameter(Mandatory)]
        [string]
        $Path,
        [Parameter()]
        [switch]
        $Quiet
    )
    $Object | ConvertTo-Json -Depth 4 | Out-File -FilePath $Path -Force
    if (!$Quiet) { return $Object }
}

function Read-Json {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]
        $Path
    )
    return Get-Content -Path $Path | ConvertFrom-Json
}

function Yes-No {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Question,
        [Parameter()]
        [boolean]
        $Default = $True
    )
    if ($Default) { $Question += " [Y\n]" } else { $Question += " [y\N]" }
    switch -regex (Read-Host $Question) {
        'y|yes' { return $True }
        'n|no' { return $False }
        '\s*?' { return $Default }
        Default {
            Yes-No -Question $Question -Default $Default
        }
    }
}
