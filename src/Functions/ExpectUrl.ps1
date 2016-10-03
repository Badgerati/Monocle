function ExpectUrl
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ExpectedUrl,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10,

        [switch] $StartsWith
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    $count = 0

    Write-MonocleHost "Waiting for URL: $ExpectedUrl" $MonocleIESession

    if ($StartsWith)
    {
        while (!$MonocleIESession.Browser.LocationURL.StartsWith($ExpectedUrl))
        {
            if ($count -ge $AttemptCount)
            {
                throw ("Expected: StartsWith $ExpectedUrl`nBut got: {0}" -f $MonocleIESession.Browser.LocationURL)
            }

            $count++
            Start-Sleep -Seconds 1
        }
    }
    else
    {
        while ($MonocleIESession.Browser.LocationURL -ine $ExpectedUrl)
        {
            if ($count -ge $AttemptCount)
            {
                throw ("Expected: $ExpectedUrl`nBut got: {0}" -f $MonocleIESession.Browser.LocationURL)
            }

            $count++
            Start-Sleep -Seconds 1
        }
    }

    Write-MonocleHost "Expected URL loaded after $count seconds(s)" $MonocleIESession
    
    SleepWhileBusy $MonocleIESession
}