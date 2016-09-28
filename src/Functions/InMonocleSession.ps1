function InMonocleSession
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [scriptblock] $ScriptBlock,

        [Parameter(Mandatory=$false)]
        [string] $ScreenshotPath,

        [switch] $Visible,
        [switch] $NotSilent,
        [switch] $KeepOpen,
        [switch] $ScreenshotOnFail
    )

    $MonocleIESession = New-Object -ComObject InternetExplorer.Application
    if (!$? -or $MonocleIESession -eq $null)
    {
        throw 'Failed to create Monocle session for IE.'
    }

    $MonocleIESession.Visible = $Visible
    $MonocleIESession.Silent = !$NotSilent

    try
    {
        & $ScriptBlock
    }
    catch [exception]
    {
        if ($ScreenshotOnFail)
        {
            $MonocleIESession.Visible = $true
            $MonocleIESession.TheaterMode = $true
            SleepWhileBusy $MonocleIESession

            if ([string]::IsNullOrWhiteSpace($ScreenshotPath))
            {
                $ScreenshotPath = $pwd
            }

            $filepath = ("$ScreenshotPath\{0}.{1}.png" -f ($Name -replace ' ', '_'), ([DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss')))

            Add-Type -AssemblyName System.Drawing

            $bitmap = New-Object System.Drawing.Bitmap $MonocleIESession.Width, $MonocleIESession.Height
            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphic.CopyFromScreen($MonocleIESession.Left, $MonocleIESession.Top, 0, 0, $bitmap.Size)
            $bitmap.Save($filepath)

            Write-Host "Screenshot saved to: $filepath"
        }

        throw $_.Exception
    }
    finally
    {
        if (!$KeepOpen)
        {
            $MonocleIESession.Quit()
        }
    }
}