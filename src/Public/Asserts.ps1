<#
.SYNOPSIS
Asserts that the current page's body has the expected value.

.DESCRIPTION
Asserts that the current page's body has the expected value.

.PARAMETER ExpectedValue
The expected value to assert that the body has.

.PARAMETER Not
If supplied, the check will be to assert the body isn't an expected value.

.EXAMPLE
Assert-MonocleBodyValue -ExpectedValue 'hello, world'
#>
function Assert-MonocleBodyValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ExpectedValue,

        [switch]
        $Not
    )

    $body = $Browser.PageSource

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

<#
.SYNOPSIS
Asserts that an element has the specified value.

.DESCRIPTION
Asserts that an element has the specified value.

.PARAMETER Element
The Element to assert.

.PARAMETER ExpectedValue
The expected value to assert that the element has.

.EXAMPLE
$Element | Assert-MonocleElementValue -ExpectedValue 'Rick'
#>
function Assert-MonocleElementValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter()]
        [string]
        $ExpectedValue
    )

    if ($Element.Text -inotmatch $ExpectedValue) {
        $id = Get-MonocleElementId -Element $Element
        throw "Element $($id)'s value is not valid.`nExpected: $($ExpectedValue)`nBut got Value: $($Element.Text)"
    }
}