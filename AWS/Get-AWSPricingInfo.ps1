

# identifiers can't start with a number so I added s_ to the front
enum Ec2Size {
    s_small;
    s_medium;
    s_large;
    s_xlarge;
    s_2xlarge;
    s_4xlarge;
    s_8xlarge;
    s_9xlarge;
    s_12xlarge;
    s_16xlarge;
    s_24xlarge;
    s_metal;
    s_32xlarge;
}

### PART 1 - Use local info to figure out which instance types are valid choices to resize to
# get relevant instance metadata
$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
$instanceId = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
$az = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone
$region = $az.Substring(0, $az.Length - 1)

$cmd = 'aws ec2 describe-instances --region $region --instance-ids $instanceId'
$instDesc = Invoke-Expression $cmd | ConvertFrom-Json
$vpcId = $instDesc.Reservations[0].Instances[0].VpcId
$ebsOptimized = $instDesc.Reservations[0].Instances[0].EbsOptimized
$enaSupport = $instDesc.Reservations[0].Instances[0].EnaSupport
$typeFamily = $instDesc.Reservations[0].Instances[0].InstanceType.Split(".")[0]
$typeSize = $instDesc.Reservations[0].Instances[0].InstanceType.Split(".")[1]
$imageId = $instDesc.Reservations[0].Instances[0].ImageId
$subnetId = $instDesc.Reservations[0].Instances[0].SubnetId
$arch = $instDesc.Reservations[0].Instances[0].Architecture

# get instance type offerings for this zone based on current instance 
$types = [System.Collections.ArrayList]@()
if($vpcId -like "vpc-*") {
    # current gen vm
    #$cmd = 'aws ec2 describe-instance-type-offerings --region $region --location-type availability-zone --filters Name=location,Values=$az'
    $cmd = 'aws ec2 describe-instance-types --region $region --filter Name=current-generation,Values=true'
    $types = Invoke-Expression $cmd | ConvertFrom-Json
} else {
    $cmd = 'aws ec2 describe-instance-types --region $region --filter Name=current-generation,Values=false'
    $types = Invoke-Expression $cmd | ConvertFrom-Json
}

# remove sizes that do not support the current architecture
$tempTypes = [System.Collections.ArrayList]@()
$types.InstanceTypes | % { if($_.ProcessorInfo.SupportedArchitectures.Contains($arch)) { $tempTypes.Add($_) > $Null } }
$types = $tempTypes

# if current is ebs optimized then only sizes that support ebsoptimized are valid
if($ebsOptimized) {
    $tempTypes = [System.Collections.ArrayList]@()
    $types | % { if( -Not($_.EbsInfo.EbsOptimizedSupport -Like "unsupported") ) { $tempTypes.Add($_) > $Null } }
    $types = $tempTypes
}

# if current is ena enabled then only sizes that support ena are valid
if($enaSupport) {
    $tempTypes = [System.Collections.ArrayList]@()
    $types | % { if( -Not($_.NetworkInfo.EnaSupport -Like "unsupported") ) { $tempTypes.Add($_) > $Null } }
    $types = $tempTypes
} 

# remove types larger than this one or smaller than small
$currentSize = [Ec2Size]::("s_" + $typeSize).value__
$tempTypes = [System.Collections.ArrayList]@()
$types | % {
    $tempSize = [Ec2Size]::("s_" + $_.InstanceType.Substring(3)).value__
    # add the type if its size is between small and the current size, inclusive
    if( ($tempSize -ge 0) -And ($tempSize -le $currentSize) ) {
        $tempTypes.Add($_) > $Null
    }
}
$types = $tempTypes

# verify all of these types can be launched in this region
$tempTypes = [System.Collections.ArrayList]@()
$types | % {
	#Write-Host $_.InstanceTYpe
    #$cmd = 'aws ec2 run-instances --instance-type $_ --dry-run --image-id $imageId --subnet-id $subnetId --region $region'
	$pinfo = New-Object System.Diagnostics.ProcessStartInfo 
	$pinfo.FileName = "aws.exe" 
	$pinfo.Arguments = ("ec2 run-instances --instance-type " + $_.InstanceType + " --dry-run --image-id $imageId --subnet-id $subnetId --region $region")
	$pinfo.UseShellExecute = $false 
	$pinfo.CreateNoWindow = $true 
	$pinfo.RedirectStandardOutput = $true 
	$pinfo.RedirectStandardError = $true
	
	# Create a process object using the startup info
	$process= New-Object System.Diagnostics.Process 
	$process.StartInfo = $pinfo
	
	# Start the process 
	$process.Start() | Out-Null 
	# Wait a while for the process to do something 
	sleep -Seconds 5 
	# If the process is still active kill it 
	if (!$process.HasExited) 
	{ 
		$process.Kill() 
	}
	
	$stderr=$process.StandardError.ReadToEnd()
	if ($stderr.Contains("Request would have succeeded")) 
	{ 
		#Write-Host "Request would have succeeded"
		$tempTypes.Add($_) > $Null
	}
}

# contains instance types we should allow
$types = $tempTypes

### PART 2 - Lookup cost info for *all* baseline instance types in the current region
# find the prices for all valid instance types in this region
$prices = aws pricing get-products --filters file://filters.json --format-version aws_v1 --service-code AmazonEC2 --region us-east-1 | ConvertFrom-Json
$priceList = $prices.PriceList | ConvertFrom-Json

# store all valid cost values in a hashtable of <instanceType, cost> pairs
$ht = [hashtable]@{}
$priceList | % { 
    $sku = ($_.terms.OnDemand | Get-Member -MemberType NoteProperty).Name
    $offer = ($_.terms.OnDemand.$sku.priceDimensions | Get-Member -MemberType NoteProperty).Name
    $cost = $_.terms.OnDemand.$sku.priceDimensions.$offer.pricePerUnit.USD

	# debugging. There *should* be only one cost entry for each instance type, but filters may be off
	if( $ht[$_.product.attributes.instanceType] -ne $Null ) {
		$_.product.attributes.instanceType + " $cost" >> .\output.txt
		$_.product.attributes >> .\output.txt
	}
	else {
		"STORING:`n" + $_.product.attributes.instanceType >> .\output.txt
		$_.product.attributes  >> .\output.txt
		$ht.Add([string]$_.product.attributes.instanceType, [decimal]$cost) > $Null
	}
}
# at this point $ht contains a single cost for each instance type in this region.

### Part 3 - output only allowed instance types and their annual costs
$output = [hashtable]@{}
$types | % { 
	#Write-Host ($_.InstanceType + " " + [math]::Round($ht[$_.InstanceType] * 8766, 2))
	$output.Add($_.InstanceType, [math]::Round($ht[$_.InstanceType] * 8766, 2)) > $Null
}

return $output