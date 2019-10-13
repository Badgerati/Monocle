function Get-MonocleBrowserPath
{
    $root = (Split-Path -Parent -Path (Get-Module -Name Monocle).Path)
    $root = (Join-Path $root 'lib')
    $root = (Join-Path $root 'Browsers')

    $os = 'win'
    if ($IsLinux) {
        $os = 'linux'
    }
    elseif ($IsMacOS) {
        $os = 'mac'
    }

    return (Join-Path $root $os)
}

function Initialize-MonocleBrowser
{
    param(
        [Parameter()]
        [string]
        $Type,

        [switch]
        $Visible
    )

    if ([string]::IsNullOrWhiteSpace($Type)) {
        $Type = 'IE'
        if ($IsLinux -or $IsMacOS) {
            $Type = 'Chrome'
        }
    }

    switch ($Type.ToLowerInvariant()) {
        'ie' {
            return Initialize-MonocleIEBrowser
        }

        'chrome' {
            return Initialize-MonocleChromeBrowser -Visible:$Visible
        }

        'firefox' {
            return Initialize-MonocleFirefoxBrowser -Visible:$Visible
        }

        default {
            throw "No browser for $($Type)"
        }
    }
}

function Initialize-MonocleIEBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.IE.InternetExplorerOptions]::new()
    $options.RequireWindowFocus = $false
    $options.IgnoreZoomLevel = $true

    $browsers = Get-MonocleBrowserPath
    return [OpenQA.Selenium.IE.InternetExplorerDriver]::new($browsers, $options)
}

function Initialize-MonocleChromeBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()

    $browsers = Get-MonocleBrowserPath
    return [OpenQA.Selenium.Chrome.ChromeDriver]::new($browsers, $options)
}

function Initialize-MonocleFirefoxBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Firefox.FirefoxOptions]::new()

    $browsers = Get-MonocleBrowserPath
    return [OpenQA.Selenium.Firefox.FirefoxDriver]::new($browsers, $options)
}