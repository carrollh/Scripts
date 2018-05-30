<#  Test-IQCredentials.ps1 
    
    Return codes:
    0 - SUCCESS
    1 - FAILURE
    >1- HTTP request failure code 
#>
Param(
    [Parameter(Mandatory=$True)]
    [string] $IQHostname,

    [Parameter(Mandatory=$True)]
    [string] $IQUsername,
    
    [Parameter(Mandatory=$True)]
    [string] $IQPassword
)

Try {
    $result = invoke-webrequest -Uri "https://$IQHostname/api/sios/stc/cldo/version"
} Catch {
    Write-Verbose "Could not find $IQHostname."
}

# verify that the iQ host can be reached
if( -Not $? ) {
    return 1
}
if ( $result.StatusCode -NotLike "200" ) {
    return $result.StatusCode
}

Try {
    # required so that self-signed pages can be retrieved using Invoke-WebRequest
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem
            ) {
                return true;
            }
        }
"@
    
    # required so that TLS mismatch does not cause a failure
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} Catch {
    Write-Verbose "Policies already exist, not adding them again."
}

# create and encode message header because Invoke-WebRequest can't figure it out otherwise  
$creds = "$($IQUsername):$($IQPassword)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

# verify credentials
Try {
    $result = Invoke-WebRequest -Uri "https://$IQHostname/api/sios/stc/cldo/environment" -Headers $Headers
    if( -Not $? ) {
        return 1
    }
    if ( $result.StatusCode -NotLike "200" ) {
        return $result.StatusCode
    }
} Catch {
    Write-Verbose "Could not find $IQHostname, despite finding it earlier."
}

# if we get here, then the credentials work
return 0
