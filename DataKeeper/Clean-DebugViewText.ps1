
Param(
    [String] $Path
)

$text = Get-Content -Path $Path

for ($i = 0; $i -lt $text.Length; $i++) { 
    if($text[$i].Length -gt 26) {
        $text[$i] = $text[$i].Substring(26).TrimStart() 
    }
}

$output = [System.Collections.ArrayList]@()
$text
$s = "OUTPUT"
$text | foreach {
    if ( ($_ -Like "ExtMirr:*") -Or ($_ -Like ">>*") -Or ($_ -Like "L: * - ") ) {
        $output.Add($s) > $Null
        $s = $_.Trim()
    } else { 
        $s += " " + $_.Trim()
    }
}
$output.Add($s) > $Null

$output.RemoveRange(0,1)

return $output