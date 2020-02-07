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
        $Position
    )

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

function Get-MonoclePageSize
{
    [CmdletBinding()]
    param()

    return @{
        Height = (Invoke-MonocleJavaScript -Script 'return document.body.scrollHeight')
        Width = (Invoke-MonocleJavaScript -Script 'return document.body.scrollWidth')
    }
}