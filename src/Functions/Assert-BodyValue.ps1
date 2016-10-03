function Assert-BodyValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ExpectedValue,

        [switch] $Contains,
        [switch] $Not
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    $body = $MonocleIESession.Browser.Document.body.outerHTML

    if ($Contains)
    {
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
    else
    {
        if ($Not)
        {
            if ($body -ieq $ExpectedValue)
            {
                throw "Document body equals '$ExpectedValue'"
            }
        }
        else
        {
            if ($body -ine $ExpectedValue)
            {
                throw "Document body does not equal '$ExpectedValue'"
            }
        }
    }
}