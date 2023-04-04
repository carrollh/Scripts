# Get-DirectoryStats.PS1

[CmdletBinding()]
param(
    [String]$Directory,
    [Switch]$Recurse
)

Write-Progress -Activity "Get-DirStats.ps1" -Status "Reading $Directory"

$files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer }

if ( $files ) {
    Write-Progress -Activity "Get-DirStats.ps1" -Status "Calculating $Directory"
    $output = $files | Measure-Object -Sum -Property Length | Select-Object `
    @{Name="Path"; Expression={$Directory}},
    @{Name="Files"; Expression={$_.Count; $script:totalcount += $_.Count}},
    @{Name="SizeGB"; Expression={($_.Sum / 1024 / 1024 / 1024); $script:totalbytes += ($_.Sum / 1024 / 1024 / 1024) }}
}
else {
    $output = "" | Select-Object `
    @{Name="Path"; Expression={$Directory}},
    @{Name="Files"; Expression={0}},
    @{Name="Size"; Expression={0}}
}

$output
