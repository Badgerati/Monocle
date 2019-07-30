function Assert-BodyValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ExpectedValue,

        [switch]
        $Not
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $body = $MonocleIESession.Browser.Document.body.outerHTML

    if ($Not) {
        if ($body -imatch $ExpectedValue) {
            throw "Document body contains '$ExpectedValue'"
        }
    }
    else {
        if ($body -inotmatch $ExpectedValue) {
            throw "Document body does not contain '$ExpectedValue'"
        }
    }
}

function Assert-ElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ExpectedValue,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession
    
    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    $value = Get-ControlValue $control

    if ($value -ine $ExpectedValue)
    {
        $innerHtml = Get-ControlValue $control -UseInnerHtml
        if ($innerHtml -ine $ExpectedValue) {
            throw "Control's value is not valid.`nExpected: $($ExpectedValue)`nBut got Value: $($value)`nand InnerHTML: $($innerHtml)"
        }
    }
}