# Get-DKCEMemoryStatistics.ps1

[CmdletBinding()]
param(
    [int] $SleepSeconds = 60,
    [int] $MaxSecondsToRun = 600
)

#$ht = [Ordered]@{}
$proclist = @('ExtMirrSvc', 'EMTray', 'MMC', 'RHS')
$elapsedTime = 0
$initialProcs = [System.Collections.ArrayList]@()
while ($elapsedTime -lt $MaxSecondsToRun) {

    # get this iteration's stats
    $procs = [System.Collections.ArrayList]@()
    foreach ($proc in $proclist) {
        $processes = get-process $proc | Sort-Object -Property Id
        foreach ($process in $processes) {
            $procs.Add($process) | Out-Null 
        }
    }
    $date = Get-Date
    #$ht.Add($date,$procs)

    # display this iteration's stats
    Write-Host "#######################################`n$($date)`nCurrent Memory Usage:"
    $procs | FT Name, Id, VM, NPM, PM, WS, PrivateMemorySize, Handles

    if($elapsedTime -eq 0) {
        $initialProcs = $procs
    }

    if($elapsedTime -gt 0) {

        # figure out the delta since the start of the script
        $deltas = [System.Collections.ArrayList]@()
        foreach ($procname in $proclist) {

            $ids = ($procs | Where-Object { $_.ProcessName -Like "$procname" }).Id
            foreach ($id in $ids) {

                $oldproc = $initialProcs | Where-Object -Property Id -eq $id
                $newProc = $procs | Where-Object -Property Id -eq $id

                $name = $procname
                if ($newProc.Modules.ModuleName -Contains "DataKeeperVolume.dll") { 
                    $name += "(DKVol)"
                }
                elseif ($newProc.Modules.ModuleName -Contains "SDRClient.dll") {
                    $name += "(DKGUI)"
                }

                $delta = [PSCustomObject]@{
                    Name = $name
                    Id = $id
                    VM = ($newproc.VM - $oldproc.VM)
                    NPM = ($newproc.NPM - $oldproc.NPM)
                    PM = ($newproc.PM - $oldproc.PM)
                    WS = ($newproc.WS - $oldproc.WS)
                    PrivateMemorySize = ($newproc.PrivateMemorySize - $oldproc.PrivateMemorySize)
                    Handles = ($newproc.Handles - $oldproc.Handles)
                }
                $deltas.Add($delta) | Out-Null
            }
        }

        # display the deltas
        Write-Host "Change since start of script:"
        $deltas | FT Name, Id, VM, NPM, PM, WS, PrivateMemorySize, Handles
    }

    if($elapsedTime -lt ($MaxSecondsToRun - $SleepSeconds)) {
        Write-Host "Sleeping for $SleepSeconds seconds..."
        Start-Sleep $SleepSeconds
    }

    $elapsedTime += $SleepSeconds
}

#return $ht