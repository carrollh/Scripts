[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$SWVersion = '',

    [Parameter(Mandatory=$True)]
    [string]$DKTimestamp = '',

    [Parameter(Mandatory=$False)]
    [string[]]$Products = @('SPSWindows', 'SPSOracle', 'SPSSQLServer', 'LKCore', 'LKLangSup', 'LKLangSupCn', 'DataKeeper')
)

$urls = [ordered]@{
    'SPSWindows' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_Protection_Suite_for_Windows_en_$($SWVersion)/SPSWindows-$($SWVersion)-setup.exe";
    'SPSOracle' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_Protection_Suite_for_Oracle_en_$($SWVersion)/SPSOracle-$($SWVersion)-setup.exe";
    'SPSSQLServer' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_Protection_Suite_for_SQL_Server_en_$($SWVersion)/SPSSQLServer-$($SWVersion)-setup.exe";
    'LKCore' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/LifeKeeper_Windows_LKCore_$($SWVersion)/LK-$($SWVersion)-Setup.exe";
    'LKLangSup' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/LifeKeeper_Windows_LKLangSup_$($SWVersion)/LKLangSup-$($SWVersion)-Setup.exe";
    'LKLangSupCn' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/LifeKeeper_Windows_LKLangSupCn_$($SWVersion)/LKLangSupCn-$($SWVersion)-Setup.exe";
    'DataKeeper' = "http://e512b7db7365eaa2f93b-44b251abad247bc1e9143294cbaa102a.r50.cf5.rackcdn.com/windows/SIOS_DataKeeper_Windows_en_$($SWVersion)/DataKeeperv$($SWVersion)-$($DKTimestamp)/DK-$($SWVersion)-Setup.exe";
}

$workingDir = "$($env:USERPROFILE)\Desktop\GAVerification\$($SWVersion)"

try {
    $ErrorActionPreference = "Stop"

    if(-Not (Test-Path -Path $workingDir)) {
        New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
    }
    cd $workingDir

    foreach ($product in $Products) {
        $exeFile = "$($workingDir)\$($product)v$($SWVersion)-Setup.exe"
        $md5File = "$($exeFile).md5sum"
        $exeUrl = $urls["$product"]
        $md5Url = "$($exeUrl).md5sum"

        $tries = 5
        while ($tries -ge 1) {
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                Write-Verbose "Trying to download from $exeUrl"
                (New-Object System.Net.WebClient).DownloadFile($exeUrl,$exeFile)

                Write-Verbose "Trying to download from $md5Url"
                (New-Object System.Net.WebClient).DownloadFile($md5Url,$md5File)

                break
            }
            catch {
                $tries--
                Write-Verbose "Exception:"
                Write-Verbose "$_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed download. Retrying again in 5 seconds"
                    Start-Sleep 5
                }
            }
        }

        $hash = (Get-FileHash -Algorithm md5 -Path $exeFile).Hash.ToUpper()
        $md5 = ((Get-Content -Path $md5File).Split())[0].ToUpper()
        Write-Verbose "Comparing $hash to $md5..."
        if($hash -eq $md5) {
            Write-Host "$product checksum verification SUCCESS"
        }
    }
}
catch {
    $_
}
