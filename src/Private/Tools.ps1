function Start-SleepWhileBusy
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session
    )

    $count = 0
    $timeout = 30
    
    while ($session.Browser.Busy)
    {
        if ($count -ge $timeout)
        {
            throw "Loading URL has timed-out after $timeout second(s)"
        }

        Start-Sleep -Seconds 1
        $count++
    }

    if ($count -gt 0)
    {
        Write-MonocleHost "Browser busy for $count seconds(s)" $session
    }
}

function Invoke-DownloadImage
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $imageSrc,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $outFile
    )

    Write-MonocleInfo "Downloading '$imageSrc' to '$outFile'" $session

    Invoke-WebRequest -Uri $imageSrc -OutFile $outFile | Out-Null
    if (!$?)
    {
        throw 'Failed to download image'
    }
}

function Write-MonocleHost
{
    param (
        $message,
        $session,
        [switch] $noTab
    )

    if ($session -ne $null -and !$session.Quiet)
    {
        if ($noTab)
        {
            Write-Host $message
        }
        else
        {
            Write-Host "`t$message"
        }
    }
}

function Write-MonocleInfo
{
    param (
        $message,
        $session
    )

    if ($session -ne $null -and $session.Info -and !$session.Quiet)
    {
        Write-Host "INFO: $message" -ForegroundColor Yellow
    }
}

function Write-MonocleError
{
    param (
        $message,
        $session,
        [switch] $noTab
    )

    if ($session -ne $null -and !$session.Quiet)
    {
        if ($noTab)
        {
            Write-Host $message -ForegroundColor Red
        }
        else
        {
            Write-Host "`t$message" -ForegroundColor Red
        }
    }
}

function Test-Url
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $url
    )

    # truncate the URL of any query parameters
    $url = ([System.Uri]$url).GetLeftPart([System.UriPartial]::Path)

    # initial code setting as success
    $code = 200
    $message = [string]::Empty

    try
    {
        $result = Invoke-WebRequest -Uri $url -TimeoutSec 30
        $code = [int]$result.StatusCode
        $message = $result.StatusDescription
    }
    catch [System.Net.WebException]
    {
        $ex = $_.Exception
        
        # if the exception doesn't contain a Response, then either the
        # host doesn't exist, there were SSL issues, or something else went wrong
        if ($ex.Response -eq $null)
        {
            $code = -1
            $message = $ex.Message
        }
        else
        {
            $code = [int]$ex.Response.StatusCode.Value__
            $message = $ex.Response.StatusDescription
        }
    }

    # anything that is 1xx-2xx is normally successful, anything that's
    # 300+ is normally always a failure to load
    # -1 is a fatal error (SSL, invalid host, etc)
    if ($code -eq -1 -or $code -ge 300)
    {
        throw "Failed to load URL: '$url'`nStatus: $code`nMessage: $message"
    }

    return $code
}

function Test-MonocleSession
{
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
}

function Set-IEFocus
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session
    )

    try
    {
        if (!([System.Management.Automation.PSTypeName]'NativeHelper').Type)
        {
            $nativeDef =
                @"
                using System;
                using System.Runtime.InteropServices;

                public static class NativeHelper
                {
                    [DllImport("user32.dll")]
                    [return: MarshalAs(UnmanagedType.Bool)]
                    private static extern bool SetForegroundWindow(IntPtr hWnd);

                    public static bool SetForeground(IntPtr handle)
                    {
                        return NativeHelper.SetForegroundWindow(handle);
                    }
                }
"@

            Add-Type -TypeDefinition $nativeDef
        }

        [NativeHelper]::SetForeground($session.Browser.HWND) | Out-Null
    }
    catch [exception]
    {
        Write-MonocleError 'Failed to bring IE to foreground' $session
    }
}

function Invoke-Screenshot
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $screenshotName,

        [string] $screenshotPath
    )

    $initialVisibleState = $session.Browser.Visible

    $session.Browser.Visible = $true
    $session.Browser.TheaterMode = $true

    Set-IEFocus $session
    Start-SleepWhileBusy $session

    if ([string]::IsNullOrWhiteSpace($screenshotPath))
    {
        $screenshotPath = $pwd
    }

    $screenshotName = ($screenshotName -replace ' ', '_')
    $filepath = Join-Path $screenshotPath "$screenshotName.png"

    Add-Type -AssemblyName System.Drawing

    $bitmap = New-Object System.Drawing.Bitmap $session.Browser.Width, $session.Browser.Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($session.Browser.Left, $session.Browser.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($filepath)

    $session.Browser.TheaterMode = $false
    $session.Browser.Visible = $initialVisibleState

    Write-MonocleHost "Screenshot saved to: $filepath" $session
}