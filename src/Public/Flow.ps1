<#
.SYNOPSIS
Returns an instance of a Selenium browser for use with Start-MonocleFlow.

.DESCRIPTION
Returns an instance of a Selenium browser for use with Start-MonocleFlow.

.PARAMETER Type
The Type of browser to create.

.PARAMETER Timeout
An optional page/load timeout in seconds. (Default: 30secs)

.PARAMETER Arguments
An optional array of Arguments to supply to the browser.

.PARAMETER Path
An optional Path to a custom driver for the browser.

.PARAMETER BinaryPath
An optional path to a custom binary for the browser.

.PARAMETER Hide
If supplied, the browser will be hidden.

.EXAMPLE
New-MonocleBrowser -Type Chrome -Hide

.EXAMPLE
New-MonocleBrowser -Type Firefox -Timeout 60
#>
function New-MonocleBrowser
{
    [CmdletBinding()]
    [OutputType([OpenQA.Selenium.Remote.RemoteWebDriver])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('IE', 'Chrome', 'Edge', 'EdgeLegacy', 'Firefox')]
        [string]
        $Type,

        [Parameter()]
        [Alias('PageTimeout')]
        [int]
        $Timeout = 30,

        [Parameter()]
        [string[]]
        $Arguments,

        [Parameter()]
        [string]
        $Path,

        [Parameter()]
        [string]
        $BinaryPath,

        [switch]
        $Hide
    )

    try {
        $Browser = Initialize-MonocleBrowser -Type $Type -Arguments $Arguments -Path $Path -BinaryPath $BinaryPath -Hide:$Hide
        if (!$? -or ($null -eq $Browser)) {
            throw 'Failed to create Browser'
        }

        Set-MonocleTimeout -Timeout $Timeout
        return $Browser
    }
    catch {
        try {
            Close-MonocleBrowser -Browser $Browser
        } catch {}
        throw
    }
}

<#
.SYNOPSIS
Closes one, or more, Selenium browsers.

.DESCRIPTION
Closes one, or more, Selenium browsers.

.PARAMETER Browser
The Selenium browser to close.

.EXAMPLE
Close-MonocleBrowser -Browser $Browser
#>
function Close-MonocleBrowser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [OpenQA.Selenium.Remote.RemoteWebDriver[]]
        $Browser
    )

    @($Browser) | ForEach-Object {
        if ($null -ne $_) {
            $type = ($_.GetType().Name -ireplace 'Driver', '')

            Write-Verbose "Closing the $($type) Browser"
            $_.Quit() | Out-Null

            Write-Verbose "Disposing the $($type) Browser"
            $_.Dispose() | Out-Null
        }
    }

    $Browser = $null
}

<#
.SYNOPSIS
Starts a Monocle flow to test a browser flow.

.DESCRIPTION
Starts a Monocle flow to test a browser flow.

.PARAMETER Name
The Name of the flow being tested.

.PARAMETER ScriptBlock
The ScriptBlock with Monocle commands to test the flow.

.PARAMETER ScreenshotPath
An optional path to save screenshots.

.PARAMETER Browser
The browser to use while testing the flow. (Default: Chrome)

.PARAMETER ScreenshotOnFail
If supplied, a screenshot will be taken if the flow fails.

.PARAMETER CloseBrowser
If supplied, the flow will auto-close the browser.

.EXAMPLE
Start-MonocleFlow -Name 'Login' -ScriptBlock {} -CloseBrowser

.EXAMPLE
Start-MonocleFlow -Name 'Login' -ScriptBlock {} -CloseBrowser -$ScreenshotPath './screenshots' -ScreenshotOnFail
#>
function Start-MonocleFlow
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter(ParameterSetName='Screenshot')]
        [Parameter()]
        [string]
        $ScreenshotPath,

        [Parameter()]
        [OpenQA.Selenium.Remote.RemoteWebDriver]
        $Browser = $null,

        [Parameter(ParameterSetName='Screenshot')]
        [switch]
        $ScreenshotOnFail,

        [switch]
        $CloseBrowser
    )

    # set the output depth
    $env:MONOCLE_OUTPUT_DEPTH = '1'

    # if no browser, set chrome as default
    if ($null -eq $Browser) {
        $CloseBrowser = $true
        $Browser = New-MonocleBrowser -Type Chrome
    }

    # invoke the logic
    try {
        Write-MonocleHost -Message "`nFlow: $Name" -NoIndent
        . $ScriptBlock
        Write-MonocleHost -Message "Flow: $Name, Success`n" -NoIndent
    }
    catch [exception]
    {
        # take a screenshot if enabled
        if ($ScreenshotOnFail) {
            $screenshotName = "$($Name)_$([DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss'))"
            $sPath = Invoke-MonocleScreenshot -Name $screenshotName -Path $ScreenshotPath
        }

        try {
            $url = Get-MonocleUrl
        } catch {}

        Write-MonocleHost -Message "Flow: $Name, Failed`n" -NoIndent

        # throw error, with last known url included
        $_.Exception.Data.Add('MonocleUrl', $url)
        $_.Exception.Data.Add('MonocleScreenshotPath', $sPath)
        throw $_.Exception
    }
    finally
    {
        # close the browser
        if ($CloseBrowser) {
            Close-MonocleBrowser -Browser $Browser
        }
    }
}

<#
.SYNOPSIS
Retries running a script X times.

.DESCRIPTION
Retries running a script X times, and errors if the last attempt is a failure.

.PARAMETER Name
A Name for the script being retried.

.PARAMETER ScriptBlock
The script to keep retrying

.PARAMETER Attempts
The number of attempts to retry. (Default: 5)

.EXAMPLE
Invoke-MonocleRetryScript -Name 'Login' -ScriptBlock {}
#>
function Invoke-MonocleRetryScript
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [int]
        $Attempts = 5
    )

    # ensure attempts >=1
    if ($Attempts -le 0) {
        $Attempts = 1
    }

    # update the depth of output
    Add-MonocleOutputDepth

    # attempt the logic
    $attempt = 1
    while ($attempt -le $Attempts) {
        Write-MonocleHost -Message "Invoking '$($Name)' logic [attempt: $($attempt)]" -Backdent

        try {
            . $ScriptBlock
            break
        }
        catch {
            $attempt++
            if ($attempt -ge $Attempts) {
                throw $_.Exception
            }

            Start-Sleep -Seconds 1
        }
    }

    # reset the depth
    Remove-MonocleOutputDepth
}