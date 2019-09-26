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

    $initialVisibleState = $Browser.Visible

    $Browser.Visible = $true
    $Browser.TheaterMode = $true

    Set-MonocleBrowserFocus
    Start-MonocleSleepWhileBusy

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $pwd
    }

    $Name = ($Name -replace ' ', '_')
    $filepath = Join-Path $Path "$($Name).png"

    Add-Type -AssemblyName System.Drawing

    $bitmap = New-Object System.Drawing.Bitmap $Browser.Width, $Browser.Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Browser.Left, $Browser.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($filepath)

    $Browser.TheaterMode = $false
    $Browser.Visible = $initialVisibleState

    Write-MonocleHost -Message "Screenshot saved to: $filepath"
    Start-MonocleSleepWhileBusy

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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath
    )

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    Write-MonocleHost -Message "Downloading image from $($result.Id)"

    $tag = $result.Element.tagName
    if (($tag -ine 'img') -and ($tag -ine 'image')) {
        throw "Element $($result.Id) is not an image element: $tag"
    }

    if ([string]::IsNullOrWhiteSpace($result.Element.src)) {
        throw "Element $($result.Id) has no src attribute"
    }

    Invoke-MonocleDownloadImage -Source $result.Element.src -Path $Path
}

function Restart-MonocleBrowser
{
    [CmdletBinding()]
    param ()

    Write-MonocleHost -Message "Refreshing the Browser"
    $Browser.Refresh()
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

    $content = $Browser.Document.IHTMLDocument3_documentElement.outerHTML

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        Write-MonocleHost -Message "Retrieving the current page's HTML content"
        return $content
    }

    Write-MonocleHost -Message "Writing the current page's HTML to '$($FilePath)'"
    $content | Out-File -FilePath $FilePath -Force | Out-Null
}