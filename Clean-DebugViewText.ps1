
Param(
    [String] $Path
)

$text = Get-Content -Path $Path

for ($i = 0; $i -lt $text.Length; $i++) { 
    $text[$i] = $text[$i].Substring(20).TrimStart() 
}

$output = [System.Collections.ArrayList]@()

$s = "OUTPUT"
$text | foreach {
    if ( ($_ -Like "ExtMirr:*") -Or ($_ -Like ">>*") ) {
        $output.Add($s) > $Null
        $s = $_.Trim()
    } else { 
        $s += " " + $_.Trim()
    }
}
$output.Add($s) > $Null

$output.RemoveRange(0,1)

return $output