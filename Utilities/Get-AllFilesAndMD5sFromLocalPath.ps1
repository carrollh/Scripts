# Get-AllFilesAndMD5sFromLocalPath.ps1

Param(
    [Parameter(Mandatory=$True,Position=0)]
    [string] $Path,
    
    [switch] $Recurse
)

$items = Get-ChildItem -Path $Path -Recurse:$Recurse

$hashes = @{}

$items | foreach {
    $hashes.Add($_.FullName, (Get-FileHash -Path $_.FullName).Hash)
}

return [System.Collections.SortedList] $hashes
