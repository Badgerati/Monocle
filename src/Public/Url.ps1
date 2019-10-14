function Set-MonocleUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter()]
        [int]
        $Attempts = 1,

        [switch]
        $Force
    )

    # ensure attempts is >=1
    if ($Attempts -le 0) {
        $Attempts = 1
    }

    # Test the URL first, ensure it exists
    $code = 0
    if (!$Force) {
        $code = Test-MonocleUrl -Url $Url -Attempts $Attempts
    }

    # Browse to the URL and wait till it loads
    $attempt = 1
    while ($attempt -le $Attempts) {
        try {
            Write-MonocleHost -Message "Navigating to: $url (Status: $code) [attempt: $($attempt)]"
            $Browser.Navigate().GoToUrl($Url) | Out-Null
            Start-MonocleSleepWhileBusy

            break
        }
        catch {
            $attempt++

            if ($attempt -gt $Attempts) {
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

        [Parameter()]
        [int]
        $Timeout = 10,

        [Parameter()]
        [int]
        $Attempts = 1,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $StartsWith
    )

    # ensure timeout and attempts is >=1
    if ($Attempts -le 0) {
        $Attempts = 1
    }

    if ($Timeout -le 0) {
        $Timeout = 1
    }

    # generic values
    $seconds = 0
    $attempt = 1

    while ($attempt -le $Attempts) {
        try {
            switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
            {
                'pattern' {
                    Write-MonocleHost -Message "Waiting for URL to match pattern: $($Pattern) [attempt: $($attempt)]"

                    while ((Get-MonocleUrl) -inotmatch $Pattern) {
                        if ($seconds -ge $Timeout) {
                            throw "Expected URL to match pattern: $($Pattern)`nBut got: $(Get-MonocleUrl)"
                        }

                        $seconds++
                        Start-Sleep -Seconds 1
                    }
                }

                'url' {
                    Write-MonocleHost -Message "Waiting for URL: $($Url) [attempt: $($attempt)]"

                    while ((!$StartsWith -and ((Get-MonocleUrl) -ine $Url)) -or ($StartsWith -and !((Get-MonocleUrl).StartsWith($Url, [StringComparison]::InvariantCultureIgnoreCase)))) {
                        if ($seconds -ge $Timeout) {
                            throw "Expected URL: $($Url)`nBut got: $(Get-MonocleUrl)"
                        }

                        $seconds++
                        Start-Sleep -Seconds 1
                    }
                }
            }

            break
        }
        catch {
            $attempt++

            if ($attempt -gt $Attempts) {
                throw $_.Exception
            }

            Start-Sleep -Seconds 1
        }
    }

    Write-MonocleHost -Message "Expected URL loaded after $($seconds * $attempt) seconds(s)"
    Start-MonocleSleepWhileBusy
}

function Wait-MonocleUrlDifferent
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $FromUrl,

        [Parameter()]
        [int]
        $Timeout = 10
    )

    # ensure timeout >=1
    if ($Timeout -le 0) {
        $Timeout = 1
    }

    # generic values
    $seconds = 0

    Write-MonocleHost -Message "Waiting for URL to change from: $($FromUrl)"

    while (($newUrl = Get-MonocleUrl) -ieq $FromUrl) {
        if ($seconds -ge $Timeout) {
            throw "Expected URL to change: From $($FromUrl)`nBut got: $($newUrl)"
        }

        $seconds++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost -Message "URL changed after $($seconds) seconds(s)"
    Start-MonocleSleepWhileBusy
}