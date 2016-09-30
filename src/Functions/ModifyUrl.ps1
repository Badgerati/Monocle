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

    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    $Url = $MonocleIESession.Browser.LocationURL -ireplace $FindValue, $ReplaceValue
    $MonocleIESession.Browser.Navigate($Url)
    SleepWhileBusy $MonocleIESession
}