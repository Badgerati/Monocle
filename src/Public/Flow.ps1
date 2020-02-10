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