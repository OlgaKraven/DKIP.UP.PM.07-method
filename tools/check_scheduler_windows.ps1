param([switch]$Collect,[switch]$Retry)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Output = Join-Path $Root 'work\runtime\scheduler-windows'
New-Item -ItemType Directory -Force -Path $Output | Out-Null
$StateFile = Join-Path $Output 'registered.json'
if ($Collect) {
    $Registered = Get-Content -LiteralPath $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $Expected = [datetime]$Registered.start
    $Expected = $Expected.AddTicks(-($Expected.Ticks % [TimeSpan]::TicksPerSecond))
    $Results = foreach ($Record in $Registered.records) {
        $Info = Get-ScheduledTaskInfo -TaskName $Record.task
        $Log = Get-Content -LiteralPath (Join-Path $Record.folder 'logs\run.log') -Raw -Encoding UTF8
        $Ends = [regex]::Matches($Log,'\[INFO\] END result=OK').Count
        if ($Info.LastTaskResult -ne 0 -or $Info.LastRunTime -lt $Expected -or $Ends -le $Record.ends_before) {
            throw "Scheduled run not yet confirmed: $($Record.task); code=$($Info.LastTaskResult); new END count=$Ends"
        }
        Export-ScheduledTask -TaskName $Record.task | Set-Content -LiteralPath (Join-Path $Output ($Record.task+'.xml')) -Encoding UTF8
        [pscustomobject]@{task=$Record.task;variant=$Record.variant;last_run=$Info.LastRunTime.ToString('o');last_result=$Info.LastTaskResult;new_success_records=($Ends-$Record.ends_before)}
    }
    $Results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $Output 'result.json') -Encoding UTF8
    $Results | Format-Table variant,last_result,new_success_records,last_run
    exit 0
}
if (Test-Path -LiteralPath $StateFile) { throw 'Existing registration record is preserved. Use -Collect.' }
$Start = (Get-Date).AddMinutes(2)
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $Identity -LogonType Interactive -RunLevel Limited
$Records = foreach ($Number in '18','19','20','21','28','22','23') {
    $Relative = if ($Number -in '22','23') { "work\runtime\native-clients\pm07_v$Number" } else { "work\runtime\sqlserver\PM07_QA_20261104_02\pm07_v$Number" }
    $Folder = Join-Path $Root $Relative
    $Script = Join-Path $Folder 'run.ps1'
    if (-not (Test-Path -LiteralPath $Script)) { throw "Missing tested script: $Number" }
    $Name = "PM07_QA_20261104_V$Number"
    $Existing = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
    if ($Existing -and (-not $Retry -or $Existing.Actions.Arguments -notlike "*$Script*")) { throw "Existing task preserved: $Name" }
    $Log = Get-Content -LiteralPath (Join-Path $Folder 'logs\run.log') -Raw -Encoding UTF8
    $Ends = [regex]::Matches($Log,'\[INFO\] END result=OK').Count
    $Action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$Script`"" -WorkingDirectory $Folder
    $Trigger = New-ScheduledTaskTrigger -Once -At $Start
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $Principal -Description 'PM07 method check (one-time)' -Force | Out-Null
    [pscustomobject]@{task=$Name;variant=$Number;folder=$Folder;ends_before=$Ends}
}
[pscustomobject]@{start=$Start.ToString('o');records=@($Records)} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $StateFile -Encoding UTF8
Write-Output "Seven one-time tasks registered for $($Start.ToString('HH:mm:ss')). No manual Run command is used."
