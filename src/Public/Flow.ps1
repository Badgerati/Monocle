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

    # create a new browser
    $Browser = New-Object -ComObject InternetExplorer.Application
    if (!$? -or ($null -eq $Browser)) {
        throw 'Failed to create Browser for IE.'
    }

    $Browser.Visible = [bool]$Visible
    $Browser.TheaterMode = $false

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
            $screenshotName = ("{0}_{1}" -f $Name, [DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss'))
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
        if (($null -ne $Browser) -and !$KeepOpen) {
            $Browser.Quit()
            $Browser = $null
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
    while ($attempt -lt $Attempts) {
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