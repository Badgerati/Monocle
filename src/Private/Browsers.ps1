function Get-MonocleBrowserPath
{
    $root = (Split-Path -Parent -Path $PSScriptRoot)
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

        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # if a path was passed, ensure it exists
    if (![string]::IsNullOrWhiteSpace($Path) -and !(Test-Path $Path)) {
        throw "Path to $($Type) driver does not exist: $($Path)"
    }

    # if type is somehow empty, set a default
    if ([string]::IsNullOrWhiteSpace($Type)) {
        $Type = 'IE'
        if ($IsLinux -or $IsMacOS) {
            $Type = 'Chrome'
        }
    }

    switch ($Type.ToLowerInvariant()) {
        'ie' {
            return Initialize-MonocleIEBrowser -Arguments $Arguments -Path $Path -Hide:$Hide
        }

        'edge' {
            return Initialize-MonocleEdgeBrowser -Arguments $Arguments -Path $Path -Hide:$Hide
        }

        'edgelegacy' {
            return Initialize-MonocleEdgeLegacyBrowser -Arguments $Arguments -Path $Path -Hide:$Hide
        }

        'chrome' {
            return Initialize-MonocleChromeBrowser -Arguments $Arguments -Path $Path -Hide:$Hide
        }

        'firefox' {
            return Initialize-MonocleFirefoxBrowser -Arguments $Arguments -Path $Path -Hide:$Hide
        }

        default {
            throw "No browser for $($Type)"
        }
    }
}

function Initialize-MonocleIEBrowser
{
    param(
        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # set the options/args
    $options = [OpenQA.Selenium.IE.InternetExplorerOptions]::new()
    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    $options.RequireWindowFocus = $false
    $options.IgnoreZoomLevel = $true

    # add arguments
    $Arguments | Sort-Object -Unique | ForEach-Object {
        $options.AddArguments($_.TrimStart('-'))
    }

    # create the browser
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-MonocleBrowserPath
    }

    $service = [OpenQA.Selenium.IE.InternetExplorerDriverService]::CreateDefaultService($Path)
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.IE.InternetExplorerDriver]::new($service, $options)
}

function Initialize-MonocleEdgeLegacyBrowser
{
    param(
        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # set the options/args
    $options = [OpenQA.Selenium.Edge.EdgeOptions]::new()

    # create the browser
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-MonocleBrowserPath
    }

    $service = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($Path)
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Edge.EdgeDriver]::new($service, $options)
}

function Initialize-MonocleChromeBrowser
{
    param(
        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # set the options/args
    $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    # needed to prevent general issues
    $Arguments += 'no-first-run'
    $Arguments += 'no-default-browser-check'
    $Arguments += 'disable-default-apps'

    # these are needed to allow running in a container
    $Arguments += 'no-sandbox'
    $Arguments += 'disable-dev-shm-usage'

    # hide the browser?
    if ($Hide -or ($env:MONOCLE_HEADLESS -ieq '1')) {
        $Arguments += 'headless'
    }

    # add arguments
    $Arguments | Sort-Object -Unique | ForEach-Object {
        $options.AddArguments($_.TrimStart('-'))
    }

    # create the browser
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-MonocleBrowserPath
    }

    $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($Path)
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Chrome.ChromeDriver]::new($service, $options)
}

function Initialize-MonocleEdgeBrowser
{
    param(
        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # set the options/args
    $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    # needed to prevent general issues
    $Arguments += 'no-first-run'
    $Arguments += 'no-default-browser-check'
    $Arguments += 'disable-default-apps'

    # these are needed to allow running in a container
    $Arguments += 'no-sandbox'
    $Arguments += 'disable-dev-shm-usage'

    # hide the browser?
    if ($Hide -or ($env:MONOCLE_HEADLESS -ieq '1')) {
        $Arguments += 'headless'
    }

    # add arguments
    $Arguments | Sort-Object -Unique | ForEach-Object {
        $options.AddArguments($_.TrimStart('-'))
    }

    # create the browser
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-MonocleBrowserPath
    }

    $driverName = 'msedgedriver.exe'
    if ($IsLinux -or $IsMacOS) {
        $driverName = 'msedgedriver'
    }

    $service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($Path, $driverName)
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Chrome.ChromeDriver]::new($service, $options)
}

function Initialize-MonocleFirefoxBrowser
{
    param(
        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [switch]
        $Hide
    )

    # set the options/args
    $options = [OpenQA.Selenium.Firefox.FirefoxOptions]::new()
    if ($null -eq $Arguments) {
        $Arguments = @()
    }

    # hide the browser?
    if ($Hide -or ($env:MONOCLE_HEADLESS -ieq '1')) {
        $Arguments += 'headless'
    }

    # add arguments
    $Arguments | Sort-Object -Unique | ForEach-Object {
        $options.AddArguments("-$($_.TrimStart('-'))")
    }

    # create the browser
    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = Get-MonocleBrowserPath
    }

    $service = [OpenQA.Selenium.Firefox.FirefoxDriverService]::CreateDefaultService($Path)
    $service.HideCommandPromptWindow = $true
    $service.SuppressInitialDiagnosticInformation = $true

    return [OpenQA.Selenium.Firefox.FirefoxDriver]::new($service, $options, [timespan]::FromSeconds(60))
}