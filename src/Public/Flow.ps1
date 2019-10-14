function New-MonocleBrowser
{
    [CmdletBinding()]
    [OutputType([OpenQA.Selenium.Remote.RemoteWebDriver])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('IE', 'Chrome', 'Firefox')]
        [string]
        $Type,

        [Parameter()]
        [int]
        $PageTimeout = 30,

        [switch]
        $Visible
    )

    $Browser = Initialize-MonocleBrowser -Type $Type -Visible:$Visible
    if (!$? -or ($null -eq $Browser)) {
        throw 'Failed to create Browser'
    }

    $Browser.Manage().Timeouts().PageLoad = [timespan]::FromSeconds($PageTimeout)
    return $Browser
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
        $type = ($_.GetType().Name -ireplace 'Driver', '')

        Write-Verbose "Closing the $($type) Browser"
        $_.Quit() | Out-Null

        Write-Verbose "Disposing the $($type) Browser"
        $_.Dispose() | Out-Null
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

        [Parameter(Mandatory=$true)]
        [OpenQA.Selenium.Remote.RemoteWebDriver]
        $Browser,

        [Parameter(ParameterSetName='Screenshot')]
        [switch]
        $ScreenshotOnFail,

        [switch]
        $CloseBrowser
    )

    # set the output depth
    $env:MONOCLE_OUTPUT_DEPTH = '1'

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
            $sPath = Invoke-MonocoleScreenshot -Name $screenshotName -Path $ScreenshotPath
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
    $env:MONOCLE_OUTPUT_DEPTH = [string](([int]$env:MONOCLE_OUTPUT_DEPTH) + 1)

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
        }
    }

    # reset the depth
    $env:MONOCLE_OUTPUT_DEPTH = [string](([int]$env:MONOCLE_OUTPUT_DEPTH) - 1)
}