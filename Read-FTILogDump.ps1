[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False, Position=0)]
    [string] $Path = "C:\Users\hcarroll.STEELEYE\Desktop\X_RW_short"
)

$pattern1 = "^.*Snapshot mirror write - O: (\w+) L: (\d+).*$"
$pattern2 = "^.*Async ReadVol (\d+) bytes at offset (\w+).*$"
$pattern3 = "^.*Write (\d+) bytes at offset (\w+).*$"

[System.Collections.ArrayList] $list = @()

foreach($line in Get-Content $Path) {
    if($m = $line | Select-String -Pattern $pattern1){
        $offset = [Int64]($m.Matches.Groups[1].Value)
        $bytes = $m.Matches.Groups[2].Value
        
        $end = $offset + $bytes
        $list.Add(($offset,$end)) > $NULL
        Write-Verbose ("SMW " + [Convert]::ToString($offset, 16) + " " + [Convert]::ToString($end, 16) + " $bytes")
        Continue
    } 
    
    if($m = $line | Select-String -Pattern $pattern2){
        $offset = [Int64]("0x" + $m.Matches.Groups[2].Value)
        $bytes = $m.Matches.Groups[1].Value
        
        $end = $offset + $bytes
        $list.Add(($offset,$end)) > $NULL
        Write-Verbose ("ARV " + [Convert]::ToString($offset, 16) + " " + [Convert]::ToString($end, 16) + " $bytes")
        Continue
    } 
    
    if($m = $line | Select-String -Pattern $pattern3){
        $offset = [Int64]("0x" + $m.Matches.Groups[2].Value)
        $bytes = $m.Matches.Groups[1].Value
        
        $end = $offset + $bytes
        $list.Add(($offset,$end)) > $NULL
        Write-Verbose ("EMW " + [Convert]::ToString($offset, 16) + " " + [Convert]::ToString($end, 16) + " $bytes")
        Continue
    }
}

return $list