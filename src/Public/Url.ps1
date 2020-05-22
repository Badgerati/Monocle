<#
.SYNOPSIS
Navigates the browser to a URL.

.DESCRIPTION
Navigates the browser to a URL, after testing if the URL is valid.

.PARAMETER Url
The URL to navigate the browser to.

.PARAMETER Force
If supplied, will skip testing the URL and just attempt to navigate to it.

.EXAMPLE
Set-MonocleUrl -Url 'https://google.com'
#>
function Set-MonocleUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [switch]
        $Force
    )

    # Test the URL first, ensure it exists
    $code = 0
    if (!$Force) {
        $code = Test-MonocleUrl -Url $Url
    }

    # Browse to the URL and wait till it loads
    $count = 1
    $timeout = Get-MonocleTimeout

    while ($count -le $timeout) {
        try {
            Write-MonocleHost -Message "Navigating to: $url (Status: $code) [attempt: $($count)]"
            $Browser.Navigate().GoToUrl($Url) | Out-Null
            Start-MonocleSleepWhileBusy

            break
        }
        catch {
            $count++
            if ($count -gt $timeout) {
                throw $_.Exception
            }

            Start-Sleep -Seconds 1
        }
    }
}

<#
.SYNOPSIS
Returns the current URL of the browser.

.DESCRIPTION
Returns the current URL of the browser.

.EXAMPLE
$url = Get-MonocleUrl
#>
function Get-MonocleUrl
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $Browser.Url
}

<#
.SYNOPSIS
Returns the page load timeout of the browser.

.DESCRIPTION
Returns the page load, and element retrieval timeout of the browser in seconds.

.EXAMPLE
$timeout = Get-MonocleTimeout
#>
function Get-MonocleTimeout
{
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $timeout = [int]$Browser.Manage().Timeouts().PageLoad.TotalSeconds
    if ($timeout -le 0) {
        $timeout = 30
    }

    return $timeout
}

<#
.SYNOPSIS
Set the page load, and element retrieval timeout.

.DESCRIPTION
Set the page load, and element retrieval timeout in seconds.

.PARAMETER Timeout
The timeout, in seconds, to wait for a page to load or to retrieve an element.

.EXAMPLE
Set-MonocleTimeout -Timeout 45
#>
function Set-MonocleTimeout
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]
        $Timeout = 30
    )

    if ($Timeout -le 0) {
        $Timeout = 30
    }

    $Browser.Manage().Timeouts().PageLoad = [timespan]::FromSeconds($Timeout)
}

<#
.SYNOPSIS
Edits the current URL using a Regex pattern.

.DESCRIPTION
Edits the current URL using a Regex pattern, and then navigate to it.

.PARAMETER Pattern
A Regex pattern to find in the URL.

.PARAMETER Value
The value to use and replace in the URL when the pattern matches.

.PARAMETER Force
If supplied, will skip testing the URL and just attempt to navigate to it.

.EXAMPLE
Edit-MonocleUrl -Pattern '\/about' -Value '/home'
#>
function Edit-MonocleUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Pattern,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $Force
    )

    $Url = ((Get-MonocleUrl) -ireplace $Pattern, $Value)
    Set-MonocleUrl -Url $Url -Force:$Force
    Start-MonocleSleepWhileBusy
}

<#
.SYNOPSIS
Wait for the browser to navigate to a URL.

.DESCRIPTION
Wait for the browser to navigate to a URL, either literally or by Regex pattern.
The wait will fail after a number of seconds greater than the browser's page load timeout.

.PARAMETER Url
A literal URL to wait for the browser to be on.

.PARAMETER Pattern
A Regex pattern to wait for the browser's URL to match.

.PARAMETER StartsWith
If supplied, and using a literal URL, will only wait till the browser's URL starts with the URL value.

.EXAMPLE
Wait-MonocleUrl -Url 'https://google.com' -StartsWith

.EXAMPLE
Wait-MonocleUrl -Pattern '.*google\.com.*'
#>
function Wait-MonocleUrl
{
    [CmdletBinding(DefaultParameterSetName='Url')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Url')]
        [string]
        $Url,

        [Parameter(Mandatory=$true, ParameterSetName='Pattern')]
        [string]
        $Pattern,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $StartsWith
    )

    # generic values
    $timeout = Get-MonocleTimeout
    $seconds = 0

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
    {
        'pattern' {
            Write-MonocleHost -Message "Waiting for URL to match pattern: $($Pattern)]"

            while ((Get-MonocleUrl) -inotmatch $Pattern) {
                if ($seconds -ge $timeout) {
                    throw "Expected URL to match pattern: $($Pattern)`nBut got: $(Get-MonocleUrl)"
                }

                $seconds++
                Start-Sleep -Seconds 1
            }
        }

        'url' {
            Write-MonocleHost -Message "Waiting for URL: $($Url)]"

            while ((!$StartsWith -and ((Get-MonocleUrl) -ine $Url)) -or ($StartsWith -and !((Get-MonocleUrl).StartsWith($Url, [StringComparison]::InvariantCultureIgnoreCase)))) {
                if ($seconds -ge $timeout) {
                    throw "Expected URL: $($Url)`nBut got: $(Get-MonocleUrl)"
                }

                $seconds++
                Start-Sleep -Seconds 1
            }
        }
    }

    Write-MonocleHost -Message "Expected URL loaded after $($seconds) seconds(s)"
    Start-MonocleSleepWhileBusy
}

<#
.SYNOPSIS
Wait for the browser to navigate away from the specified URL.

.DESCRIPTION
Wait for the browser to navigate away from the specified URL.

.PARAMETER FromUrl
The URL to wait for the browser's URL to be different to.

.EXAMPLE
Wait-MonocleUrlDifferent -FromUrl 'http://google.com'
#>
function Wait-MonocleUrlDifferent
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $FromUrl
    )

    # generic values
    $timeout = Get-MonocleTimeout
    $seconds = 0

    Write-MonocleHost -Message "Waiting for URL to change from: $($FromUrl)"

    while (($newUrl = Get-MonocleUrl) -ieq $FromUrl) {
        if ($seconds -ge $timeout) {
            throw "Expected URL to change: From $($FromUrl)`nBut got: $($newUrl)"
        }

        $seconds++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost -Message "URL changed after $($seconds) seconds(s)"
    Start-MonocleSleepWhileBusy
}