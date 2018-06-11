function Write-ToStreams
{
    [cmdletbinding()]
    Param()
    Begin
    {
        $VerbosePreference = 'Continue'
        $DebugPreference = 'Continue'
    }
    Process
    {
        Write-Host "This is written to host" -ForegroundColor Green
        Write-Output "This is written to Success output"
        Write-Error "This is an error"
        Write-Warning "This is a warning message"
        Write-Verbose "This is verbose output"
        Write-Debug "This is a debug message"
    }
}