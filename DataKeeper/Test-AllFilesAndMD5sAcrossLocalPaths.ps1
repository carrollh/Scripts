# Test-AllFilesAndMD5sAcrossLocalPaths.ps1
#
# Takes pipeline input in the form of a hashtable. Intended use is 
# Get-AllFilesAndMD5sFromLocalPath -Path <pathstring> | Test-AllFilesAndMD5sAccrossNetworkPaths -Path1 <otherpathstring> -Recurse
#. .\Get-AllFilesAndMD5sFromLocalPath
Param(
    [Parameter(Mandatory=$True,Position=0)]
    [System.String] $Path1,
    
    [Parameter(Mandatory=$False,Position=1)]
    [System.String] $Path2,
    
    [Parameter(Mandatory=$False,ValueFromPipeline=$true)]
    [System.Object] $Hashtable2,
    
    [switch] $Recurse,
    [switch] $isVerbose
)

function Test-Hashtables {
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [System.Collections.Hashtable] $ht1,
    
        [Parameter(Mandatory=$True,Position=1)]
        [System.Collections.Hashtable] $ht2
    )
    
    $mismatchCount = 0
    
    if($ht1.Count -ne $ht2.Count) {
        "ht1.Count = " + $ht1.Count + ", ht2.Count = " + $ht2.Count
    } 
    
    $ht1.Keys | foreach {
        $message = ""
        if( $ht1.Item($_) -eq $ht2.Item($_) ) {
            if($isVerbose) {
                $message = "MATCH"
            }
        } else {
            $mismatchCount += 1
            $message = "Hashes DO NOT match for $_" 
        }
        if($message -ne "") {
            $message
        }
    }

    if($mismatchCount -gt 0) {
        "Found $mismatchCount conflicting MD5 hashes"
    } else {
        "All file hashes match!"
    }
}

if($Hashtable2 -ne $NULL) {
    $inputType = $Hashtable2.GetType().Name
    
    if($inputType -eq "Hashtable") {
        $hashtable1 = .\Get-AllFilesAndMD5sFromLocalPath -Path $Path1 -Recurse:$Recurse
        Test-Hashtables -Ht1 $hashtable1 -Ht2 $Hashtable2 -Verbose:$Verbose
    } else {
        throw "Pipelined input is of wrong type. Should be System.Collections.Hastable, got $inputType instead."
    }
} else {
    $hashtable1 = .\Get-AllFilesAndMD5sFromLocalPath -Path $Path1 -Recurse:$Recurse
    $hashtable2 = .\Get-AllFilesAndMD5sFromLocalPath -Path $Path2 -Recurse:$Recurse
    Test-Hashtables -Ht1 $hashtable1 -Ht2 $hashtable2 -Verbose:$Verbose
}

