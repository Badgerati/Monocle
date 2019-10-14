function Start-MonocleSleep
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]
        $Seconds
    )

    Write-MonocleHost -Message "Sleeping for $Seconds second(s)"
    Start-Sleep -Seconds $Seconds
}

function Invoke-MonocoleScreenshot
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [string]
        $Path
    )

    $screenshot = $Browser.GetScreenshot()

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $pwd
    }

    $Name = ($Name -replace ' ', '_')
    $filepath = Join-Path $Path "$($Name).png"

    $screenshot.SaveAsFile($filepath, [OpenQA.Selenium.ScreenshotImageFormat]::Png)

    Write-MonocleHost -Message "Screenshot saved to: $filepath"

    return $filepath
}

function Save-MonocleImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

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

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath
    )

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    Write-MonocleHost -Message "Downloading image from $($result.Id)"

    $tag = $result.Element.TagName
    if (@('img', 'image') -inotcontains $tag) {
        throw "Element $($result.Id) is not an image element: $tag"
    }

    $src = $result.Element.GetAttribute('src')
    if ([string]::IsNullOrWhiteSpace($src)) {
        throw "Element $($result.Id) has no src attribute"
    }

    Invoke-MonocleDownloadImage -Source $src -Path $Path
}

function Restart-MonocleBrowser
{
    [CmdletBinding()]
    param ()

    Write-MonocleHost -Message "Refreshing the Browser"
    $Browser.Navigate().Refresh()
    Start-MonocleSleepWhileBusy
    Start-Sleep -Seconds 2
}

function Get-MonocleHtml
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $FilePath
    )

    $content = $Browser.PageSource

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        Write-MonocleHost -Message "Retrieving the current page's HTML content"
        return $content
    }

    Write-MonocleHost -Message "Writing the current page's HTML to '$($FilePath)'"
    $content | Out-File -FilePath $FilePath -Force | Out-Null
}