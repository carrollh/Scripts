# Test-DiskOfflineOnline.ps1

$disks = Get-Disk
While ($True) {
    (1..($disks.Count-1)) | foreach { 
        Set-Disk -Number $_ -IsOffline $True
    }
    (1..($disks.Count-1)) | foreach { 
        Set-Disk -Number $_ -IsOffline $False   
    }
}