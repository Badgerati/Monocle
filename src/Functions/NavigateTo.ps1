function NavigateTo
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Url
    )

    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
    
    $MonocleIESession.Navigate($Url)
    SleepWhileBusy $MonocleIESession
}