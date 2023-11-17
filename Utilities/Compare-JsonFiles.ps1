# Compare-JsonFiles.ps1
# 
# Description:
# # Run the following on two different paths/hosts
# PS> .\Get-AllFilesAndMD5sFromLocalPath.ps1 <path to compare> | ConvertTo-Json | Out-File -Encoding utf8 <filename>
# # Run the following after collecting both files above
# PS> .\Compare-JsonFiles.ps1 -FilePath1 <filename1> -FilePath2 <filename2>
#
# Example:
# (On Node1) PS> .\Get-AllFilesAndMD5sFromLocalPath.ps1 C:\LK | ConvertTo-Json | Out-File -Encoding utf8 .\hashes1.json
# (On Node2) PS> .\Get-AllFilesAndMD5sFromLocalPath.ps1 C:\LK | ConvertTo-Json | Out-File -Encoding utf8 .\hashes2.json
# (After copying hashes1 and hashes2 to local dir) PS> .\Compare-JsonFiles.ps1 -FilePath1 .\hashes1.json -FilePath2 .\hashes2.json

[CmdletBinding()]
param(
    [Parameter(Position=0,mandatory=$true)]
    [String] $FilePath1 = '',

    [Parameter(Position=1,mandatory=$true)]
    [String] $FilePath2 = ''
)

$exitcode = 0

### validate params
if (-Not (Test-Path -Path $FilePath1)) {
    Write-Error "$FilePath1 not found.`nABORTING!"
    $exitcode = 1
}

if (-Not (Test-Path -Path $FilePath2)) {
    Write-Error "$FilePath2 not found.`nABORTING!"
    $exitcode = 1
}

# abort due to error
if ($exitcode -ne 0) { exit $exitcode }


### collect data

Try {
    # collect <file,checksum> pairs from file1
    $hashes1 = $(Get-Content $FilePath1 | ConvertFrom-Json)

    # organize <file,checksum> pairs in a hashtable for easy comparison later
    $ht1 = [Hashtable]@{}
    $hashes1.psobject.properties | %{ $ht1[$_.Name] = $_.Value }

    # collect <file,checksum> pairs from file1
    $hashes2 = $(Get-Content $FilePath2 | ConvertFrom-Json)

    # organize <file,checksum> pairs in a hashtable for easy comparison later
    $ht2 = [Hashtable]@{}
    $hashes2.psobject.properties | %{ $ht2[$_.Name] = $_.Value }


    ### process data

    if ($ht1.Count -ne $ht2.Count) {
        Write-Host "Collections differ in size..."
        $exitcode = 1
    }

    # check if ht1 is missing any items from ht2
    $ht2.Keys | ForEach {
        if(-Not ($ht1.ContainsKey($_))) {
            Write-HOST -ForegroundColor Red "$_ MISSING from first collection"
            $exitcode = 1
        }
    }

    # check if ht2 is missing any items from ht1
    $ht1.Keys | ForEach {
        if (-Not ($ht2.ContainsKey($_))) {
            Write-HOST -ForegroundColor Red "$_ MISSING from second collection"
            $exitcode = 1
        }
    }

    # compare items in ht1 to items in ht2
    $comparedItems = [System.Collections.ArrayList]@()
    $ht1.Keys | ForEach {
        if ($ht1[$_] -like $ht2[$_]) {
            Write-Host "MATCH $_"
        }
        else {
            Write-Host -ForegroundColor Red "$_ does NOT match"
            $exitcode = 1
        }

        $comparedItems.Add($_) 2>&1 > $Null
    }

    $ht2.Keys | ForEach {
        if ($comparedItems.Contains($_)) { $Continue }

        if ($ht2[$_] -like $ht1[$_]) {
            Write-Host "MATCH $_"
        }
        else {
            Write-Host -ForegroundColor Red "$_ does NOT match"
            $exitcode = 1
        }
    }
}
Catch {
    Write-Host $_
    $exitcode = 1
}

exit $exitcode
