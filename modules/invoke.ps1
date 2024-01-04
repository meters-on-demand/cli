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
        $StartRainmeter
    )
    if (!$StartRainmeter -and !$StopRainmeter -and !$Bang) {
        throw "Specify either '[-Bang] <bangs>', '-StartRainmeter' or '-StopRainmeter'"
    }
    $ProgramPath = $MetersOnDemand.Cache.ProgramPath
    if ($StopRainmeter) {
        Get-Process -Name "Rainmeter" -ErrorAction Ignore | Stop-Process
    }
    if ($StartRainmeter) {
        if (!(Get-Process -Name "Rainmeter" -ErrorAction Ignore)) {
            Start-Process -FilePath "$ProgramPath"
            if ($Bang) { Start-Sleep -Milliseconds 250 }
        }
    }
    if ($Bang) {
        if ($RmApi) { $RmApi.Bang($Bang) } 
        else { Start-Process -FilePath "$ProgramPath" -ArgumentList "$($Bang)" }
    }
}
