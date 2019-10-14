function Get-MonocleBrowserPath
{
    $root = (Split-Path -Parent -Path (Get-Module -Name Monocle).Path)
    $root = (Join-Path $root 'lib')
    $root = (Join-Path $root 'Browsers')

    $os = 'win'
    $chmod = $false

    if ($IsLinux) {
        $os = 'linux'
        $chmod = $true
    }
    elseif ($IsMacOS) {
        $os = 'mac'
        $chmod = $true
    }

    $path = (Join-Path $root $os)

    if ($chmod) {
        Get-ChildItem -Path $path -Force -File | ForEach-Object {
            chmod +x $_.FullName | Out-Null
        }
    }

    return $path
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
    $service = [OpenQA.Selenium.IE.InternetExplorerDriverService]::new($browsers)

    return [OpenQA.Selenium.IE.InternetExplorerDriver]::new($service, $options)
}

function Initialize-MonocleChromeBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()

    # needed to prevent general issues
    $options.AddArguments('no-first-run')
    $options.AddArguments('no-default-browser-check')
    $options.AddArguments('disable-default-apps')

    # these are needed to allow running in a container
    $options.AddArguments('no-sandbox')
    $options.AddArguments('disable-dev-shm-usage')

    # hide the browser?
    if (!$Visible) {
        $options.AddArguments('headless')
    }

    $browsers = Get-MonocleBrowserPath
    $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($browsers)

    return [OpenQA.Selenium.Chrome.ChromeDriver]::new($service, $options)
}

function Initialize-MonocleFirefoxBrowser
{
    param(
        [switch]
        $Visible
    )

    $options = [OpenQA.Selenium.Firefox.FirefoxOptions]::new()

    $browsers = Get-MonocleBrowserPath
    $service = [OpenQA.Selenium.Firefox.FirefoxDriverService]::new($browsers)

    return [OpenQA.Selenium.Firefox.FirefoxDriver]::new($service, $options, [timespan]::FromSeconds(60))
}