function NavigateTo
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Url
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession
    
    # Test the URL first, ensure it exists
    $code = Test-Url $Url

    # Browse to the URL and wait till it loads
    Write-MonocleHost "Navigating to: $url (Status: $code)" $MonocleIESession
    $MonocleIESession.Browser.Navigate($Url)
    Start-SleepWhileBusy $MonocleIESession
}