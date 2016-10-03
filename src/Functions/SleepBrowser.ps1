function SleepBrowser
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [int] $Seconds
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
    
    Write-MonocleHost "Sleeping for $Seconds second(s)" $MonocleIESession
    Start-Sleep -Seconds $Seconds
}