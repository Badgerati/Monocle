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

        [Parameter()]
        [string]
        $ScreenshotPath,

        [switch]
        $Visible,

        [switch]
        $ScreenshotOnFail,

        [switch]
        $KeepOpen
    )

    $Browser = New-Object -ComObject InternetExplorer.Application
    if (!$? -or ($null -eq $Browser)) {
        throw 'Failed to create Browser for IE.'
    }

    $Browser.Visible = [bool]$Visible
    $Browser.TheaterMode = $false

    try {
        Write-MonocleHost -Message "`nFlow: $Name" -NoIndent
        . $ScriptBlock
        Write-MonocleHost -Message "Flow: $Name, Success`n" -NoIndent
    }
    catch [exception]
    {
        if ($ScreenshotOnFail) {
            $screenshotName = ("{0}_{1}" -f $Name, [DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss'))
            Invoke-MonocoleScreenshot -Name $screenshotName -Path $ScreenshotPath
        }

        Write-MonocleHost -Message "Flow: $Name, Failed`n" -NoIndent
        throw $_.Exception
    }
    finally
    {
        if (($null -ne $Browser) -and !$KeepOpen) {
            $Browser.Quit()
            $Browser = $null
        }
    }
}