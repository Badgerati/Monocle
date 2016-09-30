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
        [switch] $ScreenshotOnFail,
        [switch] $NotQuiet
    )

    $MonocleIESession = New-Object -TypeName PSObject |
        Add-Member -MemberType NoteProperty -Name Browser -Value $null -PassThru |
        Add-Member -MemberType NoteProperty -Name Quiet -Value $false -PassThru
    
    $MonocleIESession.Browser = New-Object -ComObject InternetExplorer.Application
    $MonocleIESession.Quiet = !$NotQuiet

    if (!$? -or $MonocleIESession -eq $null -or $MonocleIESession.Browser -eq $null)
    {
        throw 'Failed to create Monocle session for IE.'
    }

    $MonocleIESession.Browser.Visible = $Visible
    $MonocleIESession.Browser.Silent = !$NotSilent

    try
    {
        & $ScriptBlock
        Write-MonocleHost "Monocle session '$Name' Success" $MonocleIESession
    }
    catch [exception]
    {
        Write-MonocleHost "Monocle session '$Name' Failed" $MonocleIESession

        if ($ScreenshotOnFail)
        {
            $MonocleIESession.Browser.Visible = $true
            $MonocleIESession.Browser.TheaterMode = $true
            SleepWhileBusy $MonocleIESession

            if ([string]::IsNullOrWhiteSpace($ScreenshotPath))
            {
                $ScreenshotPath = $pwd
            }

            $filepath = ("$ScreenshotPath\{0}.{1}.png" -f ($Name -replace ' ', '_'), ([DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss')))

            Add-Type -AssemblyName System.Drawing

            $bitmap = New-Object System.Drawing.Bitmap $MonocleIESession.Browser.Width, $MonocleIESession.Browser.Height
            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphic.CopyFromScreen($MonocleIESession.Browser.Left, $MonocleIESession.Browser.Top, 0, 0, $bitmap.Size)
            $bitmap.Save($filepath)

            Write-MonocleHost "Screenshot saved to: $filepath" $MonocleIESession
        }

        throw $_.Exception
    }
    finally
    {
        if ($MonocleIESession.Browser -ne $null)
        {
            $MonocleIESession.Browser.Quit()
        }
    }
}