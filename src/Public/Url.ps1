function NavigateTo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Url
    )

    # Attempt to retrieve this session
    Test-MonocleSession
    
    # Test the URL first, ensure it exists
    $code = Test-Url $Url

    # Browse to the URL and wait till it loads
    Write-MonocleHost "Navigating to: $url (Status: $code)" $MonocleIESession
    $MonocleIESession.Browser.Navigate($Url)
    Start-SleepWhileBusy $MonocleIESession
}

function ModifyUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $FindValue,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ReplaceValue
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $Url = $MonocleIESession.Browser.LocationURL -ireplace $FindValue, $ReplaceValue
    $MonocleIESession.Browser.Navigate($Url)
    Start-SleepWhileBusy $MonocleIESession
}

function ExpectUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Url,

        [Parameter()]
        [int]
        $AttemptCount = 10,

        [switch]
        $StartsWith
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0

    Write-MonocleHost "Waiting for URL: $Url" $MonocleIESession

    if ($StartsWith)
    {
        while (!$MonocleIESession.Browser.LocationURL.StartsWith($Url))
        {
            if ($count -ge $AttemptCount)
            {
                throw ("Expected URL: StartsWith $Url`nBut got: {0}" -f $MonocleIESession.Browser.LocationURL)
            }

            $count++
            Start-Sleep -Seconds 1
        }
    }
    else
    {
        while ($MonocleIESession.Browser.LocationURL -ine $Url)
        {
            if ($count -ge $AttemptCount)
            {
                throw ("Expected URL: $Url`nBut got: {0}" -f $MonocleIESession.Browser.LocationURL)
            }

            $count++
            Start-Sleep -Seconds 1
        }
    }

    Write-MonocleHost "Expected URL loaded after $count seconds(s)" $MonocleIESession
    
    Start-SleepWhileBusy $MonocleIESession
}