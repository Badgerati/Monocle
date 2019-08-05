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
    Write-MonocleHost -Message "Navigating to: $url (Status: $code)"
    $Browser.Navigate($Url)
    Start-MonocleSleepWhileBusy
}

function Get-MonocleUrl
{
    [CmdletBinding()]
    param ()

    return $Browser.LocationURL
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

    $Url = $Browser.LocationURL -ireplace $Pattern, $Value
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
        $AttemptCount = 10,

        [Parameter(ParameterSetName='Url')]
        [switch]
        $StartsWith
    )

    $count = 0

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
    {
        'pattern' {
            Write-MonocleHost -Message "Waiting for URL to match pattern: $Pattern"

            while ($Browser.LocationURL -inotmatch $Pattern) {
                if ($count -ge $AttemptCount) {
                    throw "Expected URL to match pattern: $($Pattern)`nBut got: $($Browser.LocationURL)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }

        'url' {
            Write-MonocleHost -Message "Waiting for URL: $Url"

            while ((!$StartsWith -and $Browser.LocationURL -ine $Url) -or ($StartsWith -and !$Browser.LocationURL.StartsWith($Url, [StringComparison]::InvariantCultureIgnoreCase))) {
                if ($count -ge $AttemptCount) {
                    throw "Expected URL: $($Url)`nBut got: $($Browser.LocationURL)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }
    }

    Write-MonocleHost -Message "Expected URL loaded after $count seconds(s)"
    Start-MonocleSleepWhileBusy
}