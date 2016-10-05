function ExpectValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Value,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0
    
    Write-MonocleHost "Waiting for value: $Value" $MonocleIESession

    while ($MonocleIESession.Browser.Document.body.outerHTML -inotmatch $Value)
    {
        if ($count -ge $AttemptCount)
        {
            throw ("Expected value: $Value`nBut found nothing`nOn: {0}" -f $MonocleIESession.Browser.LocationURL)
        }
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected value loaded after $count second(s)" $MonocleIESession
}