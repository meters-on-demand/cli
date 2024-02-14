function Invoke-Bang {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [Alias("Bangs")]
        [string]
        $Bang,
        [Alias("Stop")]
        [switch]
        $StopRainmeter,
        [Alias("Start")]
        [switch]
        $StartRainmeter,
        [Alias("SkipIf", "NoStart")]
        [switch]
        $SkipIfNoRainmeterProcess
    )
    if (!$StartRainmeter -and !$StopRainmeter -and !$Bang) {
        throw "Specify either '[-Bang] <bangs>', '-StartRainmeter' or '-StopRainmeter'"
    }
    $ProgramPath = $MetersOnDemand.Cache.ProgramPath
    if ($StopRainmeter) {
        $rmp = Get-RainmeterProcess
        Stop-Process -Id $rmp.id
        Wait-Process -Id $rmp.id
    }
    if ($StartRainmeter) {
        if (!(Test-Rainmeter)) {
            Start-Process -FilePath "$ProgramPath"
            if ($Bang) { Start-Sleep -Milliseconds 250 }
        }
    }
    if ($Bang) {
        if ($SkipIfNoRainmeterProcess) {
            if (!(Test-Rainmeter)) { return }
        }
        if ($RmApi) { $RmApi.Bang($Bang) } 
        else { Start-Process -FilePath "$ProgramPath" -ArgumentList "$($Bang)" }
    }
}

function Test-Rainmeter { 
    return (!!(Get-RainmeterProcess))
}

function Get-RainmeterProcess {
    return Get-Process -Name Rainmeter -ErrorAction Ignore
}
