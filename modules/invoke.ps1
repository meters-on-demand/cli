function Invoke-Bang {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]
        $Bang,
        [Alias("Start")]
        [Parameter()]
        [switch]
        $StartRainmeter
    )
    if ($RmApi) { $RmApi.Bang($Bang) }
    else {
        $ProgramPath = $MetersOnDemand.Cache.ProgramPath
        if ($StartRainmeter) { 
            Start-Process -FilePath "$ProgramPath"
            if ($Bang) { Start-Sleep -Milliseconds 250 }
        }
        if ($Bang) {
            Start-Process -FilePath "$ProgramPath" -ArgumentList "$($Bang)"
        }
    }
}
