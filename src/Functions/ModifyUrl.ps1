function ModifyUrl
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $FindValue,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ReplaceValue
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $Url = $MonocleIESession.Browser.LocationURL -ireplace $FindValue, $ReplaceValue
    $MonocleIESession.Browser.Navigate($Url)
    Start-SleepWhileBusy $MonocleIESession
}