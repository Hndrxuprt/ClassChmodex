$t = Get-ScheduledTask -TaskName 'ClassCodexDailyDownload'
$t.Settings.StartWhenAvailable = $true
$t.Settings.ExecutionTimeLimit = 'PT1H'
$t.Settings.DisallowStartIfOnBatteries = $false
$t.Settings.StopIfGoingOnBatteries = $false
Set-ScheduledTask -TaskName 'ClassCodexDailyDownload' -Settings $t.Settings | Out-Null
(Get-ScheduledTask -TaskName 'ClassCodexDailyDownload').Settings |
    Select-Object StartWhenAvailable, ExecutionTimeLimit, DisallowStartIfOnBatteries, StopIfGoingOnBatteries |
    Format-List