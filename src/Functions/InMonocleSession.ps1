function InMonocleSession
{
    [CmdletBinding()]
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
        [switch] $Quiet,
        [switch] $Info,
        [switch] $ScreenshotOnFail,
        [switch] $KeepOpen
    )

    $MonocleIESession = New-Object -TypeName PSObject |
        Add-Member -MemberType NoteProperty -Name Browser -Value $null -PassThru |
        Add-Member -MemberType NoteProperty -Name Quiet -Value $false -PassThru |
        Add-Member -MemberType NoteProperty -Name Info -Value $false -PassThru

    $MonocleIESession.Browser = New-Object -ComObject InternetExplorer.Application
    $MonocleIESession.Quiet = $Quiet
    $MonocleIESession.Info = $Info

    if (!$? -or $MonocleIESession -eq $null -or $MonocleIESession.Browser -eq $null)
    {
        throw 'Failed to create Monocle session for IE.'
    }

    $MonocleIESession.Browser.Visible = $Visible
    $MonocleIESession.Browser.Silent = !$NotSilent
    $MonocleIESession.Browser.TheaterMode = $false

    try
    {
        Write-MonocleHost "Monocle session: $Name" $MonocleIESession -noTab
        & $ScriptBlock
        Write-MonocleHost "Monocle session: $Name, Success`n`n" $MonocleIESession -noTab
    }
    catch [exception]
    {
        if ($ScreenshotOnFail)
        {
            $screenshotName = ("{0}_{1}" -f $screenshotName, [DateTime]::Now.ToString('yyyy-MM-dd-HH-mm-ss'))
            Invoke-Screenshot $MonocleIESession $screenshotName $ScreenshotPath
        }

        Write-MonocleHost "Monocle session: $Name, Failed`n`n" $MonocleIESession -noTab
        throw $_.Exception
    }
    finally
    {
        if ($MonocleIESession.Browser -ne $null -and !$KeepOpen)
        {
            $MonocleIESession.Browser.Quit()
            $MonocleIESession.Browser = $null
        }
    }
}