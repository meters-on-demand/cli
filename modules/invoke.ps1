function Invoke-Bang {
    [CmdletBinding(DefaultParameterSetName = "Bang")]
    param (
        [Parameter(Mandatory, ParameterSetName = "Bang")]
        [Parameter(ParameterSetName = "Start")]
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]
        $Bang,
        [Parameter(ParameterSetName = "Start")]
        [Alias("Start")]
        [Parameter()]
        [switch]
        $StartRainmeter,
        [Parameter(ParameterSetName = "Stop")]
        [Alias("Stop")]
        [Parameter()]
        [switch]
        $StopRainmeter
    )
    if ($RmApi) { $RmApi.Bang($Bang) }
    else {
        $ProgramPath = $MetersOnDemand.Cache.ProgramPath
        if ($StopRainmeter) {
            Start-Process -FilePath "$ProgramPath" -ArgumentList "!Quit"
            return
        }
        if ($StartRainmeter) { 
            Start-Process -FilePath "$ProgramPath"
            if (!$Bang) { return }
            Start-Sleep -Milliseconds 250
        }
        Start-Process -FilePath "$ProgramPath" -ArgumentList "$($Bang)"
    }
}
