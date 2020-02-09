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

function Save-MonocleImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $FilePath
    )

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

    Invoke-MonocleDownloadImage -Source $src -Path $FilePath
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
