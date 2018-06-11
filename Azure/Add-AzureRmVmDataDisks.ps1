# PowerShell script to create a 4 read-only cache, P30(1TB) disks on a vm.
function Add-AzureRmVMDataDisks() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$VirtualMachine,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$VhdBlobUri,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$ResourceGroup,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$VolumeLetter
	)
	# lookup the vm and figure out how many data disks it already has
	$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VirtualMachine;
	$lunBase = $vm.StorageProfile.DataDisks.Lun.length;
	
	# create and add the disks
	Add-AzureRmVMDataDisk -VM $vm -Name ($VirtualMachine+"-E1") -VhdUri ($VhdBlobUri +"/"+ $VirtualMachine +"-"+ $VolumeLetter +"1.vhd") -Lun $lunBase -Caching ReadOnly -DiskSizeInGB 1023 -CreateOption Empty; $lunBase++;                                                                         
	Add-AzureRmVMDataDisk -VM $vm -Name ($VirtualMachine+"-E2") -VhdUri ($VhdBlobUri +"/"+ $VirtualMachine +"-"+ $VolumeLetter +"2.vhd") -Lun $lunBase -Caching ReadOnly -DiskSizeInGB 1023 -CreateOption Empty;	$lunBase++;                                                                         
	Add-AzureRmVMDataDisk -VM $vm -Name ($VirtualMachine+"-E3") -VhdUri ($VhdBlobUri +"/"+ $VirtualMachine +"-"+ $VolumeLetter +"3.vhd") -Lun $lunBase -Caching ReadOnly -DiskSizeInGB 1023 -CreateOption Empty;	$lunBase++;                                                                         
	Add-AzureRmVMDataDisk -VM $vm -Name ($VirtualMachine+"-E4") -VhdUri ($VhdBlobUri +"/"+ $VirtualMachine +"-"+ $VolumeLetter +"4.vhd") -Lun $lunBase -Caching ReadOnly -DiskSizeInGB 1023 -CreateOption Empty;	$lunBase++;
	
	Update-AzureRmVM -ResourceGroupName $ResourceGroup -VM $vm;
}

Add-AzureRmVMDataDisks