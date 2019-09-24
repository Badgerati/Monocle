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
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath
    )

    $value = Get-MonocleElementValue `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    if ($value -ine $ExpectedValue)
    {
        $innerHtml = Get-MonocleElementValue `
            -FilterType $PSCmdlet.ParameterSetName `
            -Id $Id `
            -TagName $TagName `
            -AttributeName $AttributeName `
            -AttributeValue $AttributeValue `
            -ElementValue $ElementValue `
            -MPath $MPath `
            -UseInnerHtml

        if ($innerHtml -ine $ExpectedValue) {
            throw "Element's value is not valid.`nExpected: $($ExpectedValue)`nBut got Value: $($value)`nand InnerHTML: $($innerHtml)"
        }
    }
}