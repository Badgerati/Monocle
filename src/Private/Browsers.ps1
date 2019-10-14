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
    return [OpenQA.Selenium.IE.InternetExplorerDriver]::new((Join-Path $browsers 'IEDriverServer.exe'), $options)
}

function Initialize-MonocleChromeBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()

    # these are needed to allow running in a container
    $options.AddArguments('no-sandbox')
    $options.AddArguments('disable-dev-shm-usage')

    # hide the browser?
    if (!$Visible) {
        $options.AddArguments('headless')
    }

    $browsers = Get-MonocleBrowserPath
    return [OpenQA.Selenium.Chrome.ChromeDriver]::new((Join-Path $browsers 'chromedriver*' -Resolve), $options)
}

function Initialize-MonocleFirefoxBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Firefox.FirefoxOptions]::new()

    $browsers = Get-MonocleBrowserPath
    return [OpenQA.Selenium.Firefox.FirefoxDriver]::new((Join-Path $browsers 'geckodriver*' -Resolve), $options)
}