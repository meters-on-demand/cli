function Set-MondAlias {
    $ScriptRoot = "$($MetersOnDemand.Cache.SkinPath)\$($MetersOnDemand.Directory)"
    $aliasFileName = "mondalias.ps1"

    $ProfileLocation = Split-Path -Path $PROFILE -Parent
    $AliasPath = "$($ProfileLocation)\$($aliasFileName)"

    $aliases = @"
Set-Alias -Name "mond" -Value "$($ScriptRoot)\$($MetersOnDemand.FileName)"
function bang { 
    param([Parameter(Position = 0)][String]`$Bang,
          [Parameter()][Alias("Start")][switch]`$StartRainmeter,
          [Parameter()][Alias("Stop")][switch]`$StopRainmeter
    )
    mond bang `$Bang -StartRainmeter:`$StartRainmeter -StopRainmeter:`$StopRainmeter
}
"@
    $aliases | Invoke-Expression
    $aliases | Out-File -FilePath "$($AliasPath)" -Force

    $profileContent = Get-Content -Path $PROFILE -Raw
    $AliasInvocation = ". `"`$(`$PSScriptRoot)\$($aliasFileName)`""
    if ($profileContent -notmatch ([Regex]::Escape($AliasInvocation))) {
        $AliasInvocation | Out-File -FilePath $PROFILE -Append
    }
    if ($MetersOnDemand.Config.AskAlias) {
        Set-Config -Option "AskAlias" -Value $False -Quiet
    }
}