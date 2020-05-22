<#
.SYNOPSIS
Just a wrapper for the Start-Sleep.

.DESCRIPTION
Just a wrapper for the Start-Sleep, but outputs some logging information.

.PARAMETER Seconds
The number of seconds to sleep.

.EXAMPLE
Start-MonocleSleep -Seconds 10
#>
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

<#
.SYNOPSIS
Takes a screenshot of the current page.

.DESCRIPTION
Takes a screenshot of the current page.

.PARAMETER Name
The name to give the screenshot when saved.

.PARAMETER Path
The path to save the screenshot. Empty will save at the current path.

.EXAMPLE
Invoke-MonocleScreenshot -Name 'the_page'
#>
function Invoke-MonocleScreenshot
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

<#
.SYNOPSIS
Saves the image source of a img element.

.DESCRIPTION
Saves the image source of a img element.

.PARAMETER Element
The img element to save the image of.

.PARAMETER Path
The path to save the image. Empty will save to the current path.

.EXAMPLE
Get-MonocleElement -Id 'image' | Save-MonocleImage
#>
function Save-MonocleImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter()]
        [Alias('FilePath')]
        [string]
        $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $pwd
    }

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Downloading image from $($id)"

    $tag = $Element.TagName
    if (@('img', 'image') -inotcontains $tag) {
        throw "Element $($id) is not an image element: $tag"
    }

    $src = Get-MonocleElementAttribute -Element $Element -Name 'src'
    if ([string]::IsNullOrWhiteSpace($src)) {
        throw "Element $($id) has no src attribute"
    }

    Invoke-MonocleDownloadImage -Source $src -Path $Path
}

<#
.SYNOPSIS
Refresh the browser.

.DESCRIPTION
Refresh the browser.

.EXAMPLE
Restart-MonocleBrowser
#>
function Restart-MonocleBrowser
{
    [CmdletBinding()]
    param()

    Write-MonocleHost -Message "Refreshing the Browser"
    $Browser.Navigate().Refresh()
    Start-MonocleSleepWhileBusy
    Start-Sleep -Seconds 2
}

<#
.SYNOPSIS
Get the HTML of the current page.

.DESCRIPTION
Get the HTML of the current page, either return it or save to a file.

.PARAMETER Path
A path to save the HTML to. Empty will use the current path.

.PARAMETER PassThru
If supplied, will instead return the HTML instead of saving it.

.EXAMPLE
$html = Get-MonocleHtml

.EXAMPLE
Get-MonocleHtml -Path './content/page.html'
#>
function Get-MonocleHtml
{
    [CmdletBinding(DefaultParameterSetName='Save')]
    param (
        [Parameter(ParameterSetName='Save')]
        [Alias('FilePath')]
        [string]
        $Path,

        [Parameter(ParameterSetName='Return')]
        [switch]
        $PassThru
    )

    $content = $Browser.PageSource
    if ($PassThru) {
        Write-MonocleHost -Message "Retrieving the current page's HTML content"
        return $content
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $pwd
    }

    Write-MonocleHost -Message "Writing the current page's HTML to '$($Path)'"
    $content | Out-File -FilePath $Path -Force | Out-Null
}

<#
.SYNOPSIS
Run some adhoc JavaScript on the current page.

.DESCRIPTION
Run some adhoc JavaScript on the current page.

.PARAMETER Script
The JavaScript to run.

.PARAMETER Arguments
Optional array of arguments to pass to the script.

.EXAMPLE
$element = Invoke-MonocleJavaScript -Script 'return document.getElementById('username')'

.EXAMPLE
$element = Invoke-MonocleJavaScript -Script 'return document.getElementById(arguments[0])' -Arguments 'username'
#>
function Invoke-MonocleJavaScript
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Script,

        [Parameter()]
        [object[]]
        $Arguments
    )

    $Browser.ExecuteScript($Script, $Arguments)
}

<#
.SYNOPSIS
Downloads a custom driver for a specific browser version.

.DESCRIPTION
Downloads a custom driver for a specific browser version.

.PARAMETER Type
The type of driver.

.PARAMETER Version
The version of the driver.

.EXAMPLE
Install-MonocleDriver -Type Chrome -Version '79.0.3945.3600'
#>
function Install-MonocleDriver
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('IE', 'Chrome', 'Firefox')]
        [string]
        $Type,

        [Parameter(Mandatory=$true)]
        [string]
        $Version
    )

    # create the custom driver folder
    $customDir = Get-MonocleCustomDriverPath
    New-Item -Path $customDir -ItemType Directory -Force -ErrorAction Stop | Out-Null

    # remove temp if it exists
    $tempDir = Join-Path $customDir 'temp'
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Force -Recurse -ErrorAction Stop | Out-Null
    }

    # down the driver to a temp dir within custom
    $driverName = (@{
        Chrome = 'Selenium.WebDriver.ChromeDriver'
        IE = 'Selenium.WebDriver.IEDriver'
        Firefox = 'Selenium.WebDriver.GeckoDriver'
    })[$Type]

    Write-Host "Downloading $($Type) [$($Version)] driver..."
    nuget install $driverName -version $Version -outputdirectory $tempDir | Out-Null
    if (!$?) {
        throw "Failed to download the $($Type) [$($Version)] driver"
    }

    # create the os dirs
    $winDir = Join-Path $customDir 'win'
    $nixDir = Join-Path $customDir 'linux'
    $macDir = Join-Path $customDir 'mac'

    New-Item -Path $winDir -ItemType Directory -Force | Out-Null
    New-Item -Path $nixDir -ItemType Directory -Force | Out-Null
    New-Item -Path $macDir -ItemType Directory -Force | Out-Null

    # move the drivers into an appropraite structure
    switch ($Type.ToLowerInvariant()) {
        'ie' {
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/*" -Destination $winDir -Recurse -Force | Out-Null
        }

        'chrome' {
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/win32/*" -Destination $winDir -Recurse -Force | Out-Null
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/linux64/*" -Destination $nixDir -Recurse -Force | Out-Null
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/mac64/*" -Destination $macDir -Recurse -Force | Out-Null
        }

        'firefox' {
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/win64/*" -Destination $winDir -Recurse -Force | Out-Null
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/linux64/*" -Destination $nixDir -Recurse -Force | Out-Null
            Copy-Item -Path "$($tempDir)/$($driverName).$($Version)/driver/mac64/*" -Destination $macDir -Recurse -Force | Out-Null
        }
    }

    # remove the temp dir in custom
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Force -Recurse -ErrorAction Stop | Out-Null
    }
}
