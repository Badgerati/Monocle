function Assert-BodyValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ExpectedValue,

        [switch] $Not
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    $body = $MonocleIESession.Browser.Document.body.outerHTML

    if ($Not)
    {
        if ($body -imatch $ExpectedValue)
        {
            throw "Document body contains '$ExpectedValue'"
        }
    }
    else
    {
        if ($body -inotmatch $ExpectedValue)
        {
            throw "Document body does not contain '$ExpectedValue'"
        }
    }
}