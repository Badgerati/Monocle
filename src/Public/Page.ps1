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

function Get-MonoclePageSize
{
    [CmdletBinding()]
    param()

    return @{
        Height = (Invoke-MonocleJavaScript -Script 'return document.body.scrollHeight')
        Width = (Invoke-MonocleJavaScript -Script 'return document.body.scrollWidth')
    }
}