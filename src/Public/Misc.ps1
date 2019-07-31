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
}

function Save-MonocleImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

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

    Write-MonocleHost -Message "Downloading image from $ElementName"

    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    $tag = $element.tagName
    if (($tag -ine 'img') -and ($tag -ine 'image')) {
        throw "Element $ElementName is not an image element: $tag"
    }

    if ([string]::IsNullOrWhiteSpace($element.src)) {
        throw "Element $ElementName has no src attribute"
    }

    Invoke-MonocleDownloadImage -Source $element.src -Path $Path
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