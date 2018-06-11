# wraps creation of pscustomobjects to make creating config objects easier/readable at all

# Example use:
# PS> $property = @{Name='My Object';One=1;Two=2;Three=3;Four=4} 
# PS> New-PSCustomObject -Property $property -DefaultProperties Name,Two,Four 
function New-PSCustomObject() {
       [CmdletBinding()] 

       param(
              [Parameter(Mandatory,Position=0)]
              [ValidateNotNullOrEmpty()]
              [System.Collections.Hashtable]$Property,

              [Parameter(Position=1)]
              [ValidateNotNullOrEmpty()]
              [Alias('dp')]
              [System.String[]]$DefaultProperties
       )

       $psco = [PSCustomObject]$Property 

       # define a subset of properties
       $ddps = New-Object System.Management.Automation.PSPropertySet `
                DefaultDisplayPropertySet,$DefaultProperties
       $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$ddps 

       # Attach default display property set
       $psco | Add-Member -MemberType MemberSet -Name PSStandardMembers `
                -Value $PSStandardMembers -PassThru
}