# New-JenkinsDKCEStack.ps1
# 
# Example usage:
#   PS> .\New-JenkinsDKCEStack.ps1
#

[CmdletBinding()]
Param()

Try {
    # deploy the jenkins stack
    $stackName = 'WinDev-WS2022-JENKINS'
    $stackId = (& "aws" cloudformation create-stack --region us-east-1 --stack-name $stackName --template-url https://quickstart-sios-qa.s3.amazonaws.com/master/templates/sios-datakeeper-jenkins-1x1.yaml --capabilities CAPABILITY_IAM --output json | convertfrom-json).StackId
    
    if($? -eq $TRUE) {
        Write-Verbose $stackId
    }
    else {
        Write-Error "FAILED to deploy jenkins stack"
    }

    $stack = $Null
    do {
        Start-Sleep -Seconds 60
        $stack = (& "aws" cloudformation describe-stacks --region us-east-1 --stack-name $stackName --output json | ConvertFrom-Json)
    } while ($stack.Stacks[0].StackStatus -like 'CREATE_IN_PROGRESS');

    if($stack.Stacks[0].StackStatus -like 'CREATE_COMPLETE') {
        Write-Verbose $stack.Stacks[0]
        return 0
    }
    else {
        Write-Error "FAILED deployment of jenkins stack"
    }
}
Catch {
    $_
    return 1
}

return 0