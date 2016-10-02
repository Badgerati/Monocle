function NavigateTo
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Url
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
    
    # Test the URL first, ensure it exists
    $code = Test-Url $Url

    # Browse to the URL and wait till it loads
    Write-MonocleHost "Navigating to: $url (Status: $code)"
    $MonocleIESession.Browser.Navigate($Url)
    SleepWhileBusy $MonocleIESession
}