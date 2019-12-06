#Set-AWSImageIds.ps1


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [HashTable] $HashTable = $Null,

    [Parameter(Mandatory=$False)]
    [String] $Path = "C:\GitHub\quickstart-sios-datakeeper\templates\sios-datakeeper.template"
)

#$text = Get-Content $Path -Raw | Out-String
$output = ""
$regions = $HashTable.Keys | Sort
foreach ( $region in $regions ) {
    $map = $HashTable[$region]
    $output += "    $region" + ":`n"

    $osVersions = $map.Keys | Sort
    foreach ( $osVersion in $osVersions ) {
        $amiId = $map[$osVersion]
        $output += "      SDKCEWIN" + $osVersion + ": $amiId`n"
    }

    <#
        $pattern = $region + ":?!.*(:`n)*.*(SDKCEWIN" + $osV + ": ami-.*)`n.*:`n"
        $text -Match $pattern

        Write-Verbose "$region $pattern"  
        foreach ($m in $Matches) {
            Write-Host "0 " $Matches[0]
            Write-Host "1 " $Matches[2]
        }
    }
#>
}

Write-Host $output
