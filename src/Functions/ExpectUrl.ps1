function ExpectUrl
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Url,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10,

        [switch] $StartsWith
    )

    # Attempt to retrieve this sessions Monocle
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