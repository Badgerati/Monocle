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

function Get-MonocleUrl
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $Browser.Url
}

function Get-MonocleTimeout
{
    [CmdletBinding()]
    [OutputType([int])]
    param()

    return [int]$Browser.Manage().Timeouts().PageLoad.TotalSeconds
}

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