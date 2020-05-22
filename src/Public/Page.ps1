<#
.SYNOPSIS
Scroll the current webpage.

.DESCRIPTION
Scroll the current webpage to a specific element, or a position.

.PARAMETER To
Scroll to the top or bottom of the page.

.PARAMETER Position
Scroll to a specific height of the page.

.PARAMETER Element
Scroll to an element on the page.

.EXAMPLE
Move-MonoclePage -To Bottom

.EXAMPLE
Get-MonocleElement -Id 'image' | Move-MonoclePage
#>
function Move-MonoclePage
{
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='To')]
        [ValidateSet('Bottom', 'Middle', 'Top')]
        [string]
        $To,

        [Parameter(ParameterSetName='Position')]
        [int]
        $Position,

        [Parameter(ParameterSetName='Element', ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant()) {
        # literal positions
        { @('to', 'position') -icontains $_ } {
            if ($PSCmdlet.ParameterSetName -ieq 'to') {
                $size = Get-MonoclePageSize
                $Position = (@{
                    Bottom = $size.Height
                    Middle = $size.Height * 0.5
                    Top = 0
                })[$To]
            }
    
            Write-MonocleHost -Message "Scrolling to: $Position"
            Invoke-MonocleJavaScript -Arguments $Position -Script 'window.scrollTo(0, arguments[0])' | Out-Null
        }

        # elements
        'element' {
            $id = Get-MonocleElementId -Element $Element
            Write-MonocleHost -Message "Moving page to element: $($id)"
            Invoke-MonocleJavaScript -Arguments $Element -Script 'arguments[0].scrollIntoView(true)' | Out-Null
        }
    }
}

<#
.SYNOPSIS
Returns the size of the current webpage.

.DESCRIPTION
Returns the size of the current webpage, as a Hashtable with Height/Width.

.EXAMPLE
$size = Get-MonoclePageSize
#>
function Get-MonoclePageSize
{
    [CmdletBinding()]
    param()

    return @{
        Height = (Invoke-MonocleJavaScript -Script 'return document.body.scrollHeight')
        Width = (Invoke-MonocleJavaScript -Script 'return document.body.scrollWidth')
    }
}