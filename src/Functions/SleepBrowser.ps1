function SleepBrowser
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [int] $Seconds
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession
    
    Write-MonocleHost "Sleeping for $Seconds second(s)" $MonocleIESession
    Start-Sleep -Seconds $Seconds
}