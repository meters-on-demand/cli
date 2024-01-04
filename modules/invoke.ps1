function Invoke-Bang {
    [CmdletBinding(DefaultParameterSetName = "Bang")]
    param (
        [Parameter(Mandatory, ParameterSetName = "Bang")]
        [Parameter(ParameterSetName = "Start")]
        [Parameter(ParameterSetName = "Stop")]
        [Parameter(Position = 0, ValueFromPipeline)]
        [Alias("Bangs")]
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
        $StopRainmeter,
        [Parameter()]
        [switch]
        $Quiet
    )
    if ($RmApi) { $RmApi.Bang($Bang) }
    else {
        $ProgramPath = $MetersOnDemand.Cache.ProgramPath
        if ($StartRainmeter -and $StopRainmeter -and !$Bang -and !$Quiet) {
            Write-Host "Starting and stopping Rainmeter without bangs..."
            Write-Host "Use -Quiet to supress I guess? You should not do this!!?!"
        }
        if ($StartRainmeter) { 
            Start-Process -FilePath "$ProgramPath"
            if ($Bang) { Start-Sleep -Milliseconds 250 }
        }
        if ($Bang) {
            Start-Process -FilePath "$ProgramPath" -ArgumentList "$($Bang)"
        }
        if ($StopRainmeter) {
            Get-Process -Name "Rainmeter" -ErrorAction Ignore | Stop-Process
            return
        }
    }
}
