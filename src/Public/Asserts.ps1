function Assert-MonocleBodyValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ExpectedValue,

        [switch]
        $Not
    )

    $body = $Browser.Document.body.outerHTML

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

function Assert-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
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

    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    $value = Get-MonocleElementValue -Element $element

    if ($value -ine $ExpectedValue)
    {
        $innerHtml = Get-MonocleElementValue -Element $element -UseInnerHtml
        if ($innerHtml -ine $ExpectedValue) {
            throw "Element's value is not valid.`nExpected: $($ExpectedValue)`nBut got Value: $($value)`nand InnerHTML: $($innerHtml)"
        }
    }
}