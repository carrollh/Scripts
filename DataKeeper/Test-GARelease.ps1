# Quick Script to download and verify all GA files 
# The version param should have the format "8.5.0"
# The build param should have the format "2107"
Param(
	[Parameter(Mandatory=$True)]
	[System.String]$version,
	
	[Parameter(Mandatory=$True)]
	[System.String]$build
)

function Test-ReleaseDKCE() {
	$webpath 	= "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_DataKeeper_Windows_en_$version/"
	$localpath 	= "$env:userprofile\Downloads"
	$files 		= @( 
					"EULA.pdf",
					"DataKeeperv$version-$build/DK-$version-Setup.exe",
					"DataKeeperv$version-$build/DK-$version-Setup.exe.md5sum"
				)
	
	$results = $true;
	
	if( Test-Path "$localpath\DataKeeperv$version-$build" ) { rmdir "$localpath\DataKeeperv$version-$build" -Recurse -Force }
	mkdir "$localpath\DataKeeperv$version-$build" 
				
	foreach ($file in $files) {
		"Downloading {0}" -f $file
		Invoke-WebRequest -Uri ("{0}/{1}" -f $webpath,$file) -OutFile ("{0}\{1}" -f $localpath,$file)  
		if (-NOT (Test-Path ("{0}\{1}" -f $localpath,$file))) {
			Write-Warning ("FILE {0}\{1} NOT FOUND!" -f $localpath,$file)
			$results = $false
		}
	}
	
	$hashFromFile = [char[]](Get-Content ("{0}\{1}" -f $localpath,$files[2]) -Encoding byte -TotalCount 32)
	$hash = -join $hashFromFile
	$fileHash = Get-FileHash -Algorith MD5 ("{0}\{1}" -f $localpath,$files[1])
	if( -NOT $hash.ToUpper().Equals($fileHash.Hash.ToUpper()) ) {
		Write-Warning ("{0} NOT EQUAL TO {1}" -f $hash,$fileHash.Hash)
		$results = $false
	} else {
		Write-Host ("{0} EFFECTIVELY EQUAL TO {1}" -f $hash,$fileHash.Hash)
	}
	
	return $results
}

function Test-ReleaseSPSWindows() {
	Param (
		[Parameter(Mandatory=$True)]
		[System.String]$product
	)
	
	$webpath 	= "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_Protection_Suite_for_{0}_en_{1}" -f $product,$version
	$localpath 	= "$env:userprofile\Downloads"
	
	$prod = $product
	if( $product.Equals("Windows") )	{ $prod = "SPSWindows" }
	if( $product.Equals("Oracle") ) 	{ $prod = "SPSOracle" }
	if( $product.Equals("SQL_Server") )	{ $prod = "SPSSQLServer" }
	
	$files 		= @( 
					"EULA.pdf",
					"$prod-$version-setup.exe",
					"$prod-$version-setup.exe.md5sum"
				)
	
	$results = $true;
				
	foreach ($file in $files) {
		"Downloading {0}" -f $file
		Invoke-WebRequest -Uri ("{0}/{1}" -f $webpath,$file) -OutFile ("{0}\{1}" -f $localpath,$file) 
		if (-NOT (Test-Path ("{0}\{1}" -f $localpath,$file))) {
			Write-Warning ("FILE {0}\{1} NOT FOUND!" -f $localpath,$file)
			$results = $false
		}
	}
	
	$hashFromFile = [char[]](Get-Content ("{0}\{1}" -f $localpath,$files[2]) -Encoding byte -TotalCount 32)
	$hash = -join $hashFromFile
	$fileHash = Get-FileHash -Algorith MD5 ("{0}\{1}" -f $localpath,$files[1])
	if( -NOT $hash.ToUpper().Equals($fileHash.Hash.ToUpper()) ) {
		Write-Warning ("{0} NOT EQUAL TO {1}" -f $hash,$fileHash.Hash)
		$results = $false
	} else {
		Write-Host ("{0} EFFECTIVELY EQUAL TO {1}" -f $hash,$fileHash.Hash)
	}
	
	return $results
}

function Test-ReleaseWindows() {
	Param (
		[Parameter(Mandatory=$True)]
		[System.String]$product
	)
	$webpath 	= "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/LifeKeeper_Windows_{0}_{1}" -f $product,$version
	$localpath 	= "$env:userprofile\Downloads"
	
	$prod = $product
	if( $product.Equals("LKCore") ) 							 { $prod = "LK" }
	if( $product.Equals("Oracle_RK") )							 { $prod = "LKOra" }
	if( $product.Equals("SQL_RK") )								 { $prod = "LKSQL" }
	
	$files 		= @( 
					"$prod-$version-Setup.exe",
					"$prod-$version-Setup.exe.md5sum"
				)
	
	$results = $true;
				
	foreach ($file in $files) {
		"Downloading {0}" -f $file
		Invoke-WebRequest -Uri ("{0}/{1}" -f $webpath,$file) -OutFile ("{0}\{1}" -f $localpath,$file) 
		if (-NOT (Test-Path ("{0}\{1}" -f $localpath,$file))) {
			Write-Warning ("FILE {0}\{1} NOT FOUND!" -f $localpath,$file)
			$results = $false
		}
	}
	
	$hashFromFile = [char[]](Get-Content ("{0}\{1}" -f $localpath,$files[1]) -Encoding byte -TotalCount 32)
	$hash = -join $hashFromFile
	$fileHash = Get-FileHash -Algorith MD5 ("{0}\{1}" -f $localpath,$files[0])
	if( -NOT $hash.ToUpper().Equals($fileHash.Hash.ToUpper()) ) {
		Write-Warning ("{0} NOT EQUAL TO {1}" -f $hash,$fileHash.Hash)
		$results = $false
	} else {
		Write-Host ("{0} EFFECTIVELY EQUAL TO {1}" -f $hash,$fileHash.Hash)
	}
	
	return $results
}

Test-ReleaseDKCE
Test-ReleaseSPSWindows -Product Windows
Test-ReleaseSPSWindows -Product Oracle
Test-ReleaseSPSWindows -Product SQL_Server
Test-ReleaseWindows -Product LKCore
Test-ReleaseWindows -Product LKLangSup
Test-ReleaseWindows -Product LKLangSupCn
Test-ReleaseWindows -Product Oracle_RK
Test-ReleaseWindows -Product SQL_RK
