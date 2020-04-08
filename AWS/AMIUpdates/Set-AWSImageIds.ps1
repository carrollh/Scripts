#Set-AWSImageIds.ps1
# PS> .\Set-AWSImageIds -Profile dev -Version 9.4.1 -OSVersions "RHEL 7.7" -Template SPSL
# PS> .\Set-AWSImageIds -Profile dev -Version 8.7.1 -OSVersions "all" -Template DK


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$True, Position=1)]
    [string[]] $Version = $Null,

    [Parameter(Mandatory=$True, Position=2)]
    [string[]] $OSVersions = $Null,

    [Parameter(Mandatory=$True, Position=3)]
    [ValidateSet("SPSL","DK","SAP")]
    [String] $Template = $Null,

    [Parameter(Mandatory=$False, Position=4)]
    [String] $OutDir = $Null
)

if($OutDir -eq $Null -Or $OutDir -eq "") {
    $OutDir = $PSScriptRoot
}

$regions = @("ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")

$content = ""
$outfile = ""
$ht = [System.Collections.Hashtable]@{}
Switch ($Template){
    "DK" { 
        $ht = $ht = .\Get-AWSAMIIds -Profile $Profile -Version $Version -OSversion $OSVersions -Regions $regions

        # compose the DKCE template output mapping
        $regions | % { 
            $content += "    " + $_ + ":`n"
            $content += "      SDKCEWIN2012R2: " + $ht[$_]["SDKCEWIN2012R2"] + "`n"
            $content += "      SDKCEWIN2012R2BYOL: " + $ht[$_]["SDKCEWIN2012R2BYOL"] + "`n"
            $content += "      SDKCEWIN2016: " + $ht[$_]["SDKCEWIN2016"] + "`n"
            $content += "      SDKCEWIN2016BYOL: " + $ht[$_]["SDKCEWIN2016BYOL"] + "`n"
            $content += "      SDKCEWIN2019: " + $ht[$_]["SDKCEWIN2019"] + "`n"
            $content += "      SDKCEWIN2019BYOL: " + $ht[$_]["SDKCEWIN2019BYOL"] + "`n"
        }
        $outfile = "$OutDir\sios-datakeeper-mappings.yaml"
        Write-Host "writing to $outfile"
        $content > $outfile
     }
    {$_ -in "SPSL","SAP"} { # both the SPSL and SAP templates need the same values from Get-AWSAMIIds currently
        $ht = $ht = .\Get-AWSAMIIds -Profile $Profile -Version $Version -OSversion $OSVersions -Regions $regions -Linux

        # compose the SPSL template output mapping
        $regions | % { 
            $content += "    " + $_ + ":`n"
            $content += "      SPSLRHEL: " + $ht[$_]["SPSLRHEL"] + "`n"
            $content += "      SPSLRHELBYOL: " + $ht[$_]["SPSLRHELBYOL"] + "`n"
            $content += "      WS2016FULLBASE: " + $ht[$_]["WS2016FULLBASE"] + "`n"
        }
        $outfile = "$OutDir\sios-protection-suite-mappings.yaml"
        Write-Host "writing to $outfile"
        $content > $outfile

        # compose the SAP template output mapping
        $regions | % { 
            $content += "    " + $_ + ":`n"
            $content += "      SPSLSLESSAPBYOL: ami-`n"
            $content += "      SPSLRHELBYOL: " + $ht[$_]["SPSLRHELBYOL"] + "`n"
            $content += "      WS2016FULLBASE: " + $ht[$_]["WS2016FULLBASE"] + "`n"
        }
        $outfile = "$OutDir\sios-protection-suite-s4hana-mappings.yaml"
        Write-Host "writing to $outfile"
        $content > $outfile
    }
}

return $ht
