function Screenshot
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Name,

        [Parameter(Mandatory=$false)]
        [string] $Path
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Invoke-Screenshot $MonocleIESession $Name $Path
    Start-SleepWhileBusy $MonocleIESession
}