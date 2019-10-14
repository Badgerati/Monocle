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
        $Hide
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
            return Initialize-MonocleChromeBrowser -Hide:$Hide
        }

        'firefox' {
            return Initialize-MonocleFirefoxBrowser -Hide:$Hide
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
        $Hide
    )

    $options = [OpenQA.Selenium.IE.InternetExplorerOptions]::new()
    $options.RequireWindowFocus = $false
    $options.IgnoreZoomLevel = $true

    $service = [OpenQA.Selenium.IE.InternetExplorerDriverService]::CreateDefaultService((Get-MonocleBrowserPath))
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.IE.InternetExplorerDriver]::new($service, $options)
}

function Initialize-MonocleChromeBrowser
{
    param(
        [switch]
        $Hide
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
    if ($Hide -or ($env:MONOCLE_HEADLESS -ieq '1')) {
        $options.AddArguments('headless')
    }

    $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService((Get-MonocleBrowserPath))
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Chrome.ChromeDriver]::new($service, $options)
}

function Initialize-MonocleFirefoxBrowser
{
    param(
        [switch]
        $Hide
    )

    $options = [OpenQA.Selenium.Firefox.FirefoxOptions]::new()

    # hide the browser?
    if ($Hide -or ($env:MONOCLE_HEADLESS -ieq '1')) {
        $options.AddArguments('-headless')
    }

    $service = [OpenQA.Selenium.Firefox.FirefoxDriverService]::CreateDefaultService((Get-MonocleBrowserPath))
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Firefox.FirefoxDriver]::new($service, $options, [timespan]::FromSeconds(60))
}