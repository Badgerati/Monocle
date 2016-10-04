

$root = Split-Path -Path $MyInvocation.MyCommand.Path
Get-ChildItem "$root\Functions\*.ps1" |
    Resolve-Path |
    ForEach-Object { . $_ }


function Start-SleepWhileBusy($session)
{
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


function Test-ControlNull($control)
{
    return $control -eq $null -or $control -eq [System.DBNull]::Value
}


function Get-Control($session, $name, $tagName = $null, $attributeName = $null, [switch]$findByValue, [switch]$noThrow)
{
    $document = $session.Browser.Document

    # If they're set, retrieve control by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($tagName) -and ![string]::IsNullOrWhiteSpace($attributeName))
    {
        Write-MonocleInfo "Finding control with tag <$tagName>, attribute '$attributeName' and value '$name'" $session

        $control = $document.getElementsByTagName($tagName) |
            Where-Object { $_.getAttribute($attributeName) -imatch $name } |
            Select-Object -First 1

        # Throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow)
        {
            throw "Element <$tagName> with attribute '$attributeName' value of $name not found."
        }

        return $control
    }

    # If they're set, retrieve the control by tag/value combo (value then innerHTML)
    if (![string]::IsNullOrWhiteSpace($tagName) -and $findByValue)
    {
        Write-MonocleInfo "Finding control with tag <$tagName>, and value '$name'" $session

        $controls = $document.getElementsByTagName($tagName)

        $control = $controls |
            Where-Object { $_.value -ieq $name }
            Select-Object -First 1
        
        if (Test-ControlNull $control)
        {
            $control = $controls |
                Where-Object { $_.innerHTML -ieq $name }
                Select-Object -First 1
        }
        
        # Throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow)
        {
            throw "Element <$tagName> with value of $name not found."
        }

        return $control
    }

    # If no tag/attr combo, attempt to retrieve by ID
    Write-MonocleInfo "Finding control with identifier '$name'" $session
    $control = $document.getElementById($name)

    # If no control by ID, try by first named control
    if (Test-ControlNull $control)
    {
        Write-MonocleInfo "Finding control with name '$name'" $session
        $control = $document.getElementsByName($name) | Select-Object -First 1
    }

    # Throw error if can't find control
    if ((Test-ControlNull $control) -and !$noThrow)
    {
        throw "Element with ID/Name of $name not found."
    }

    return $control
}


function Get-ControlValue($control, [switch]$useInnerHtml)
{
    # Get the value of the control, if it's a select control, get the appropriate
    # option where option is selected
    if ($control.Length -gt 1 -and $control[0].tagName -ieq 'option')
    {
        return ($control | Where-Object { $_.Selected -eq $true }).innerHTML
    }

    # If not a select control, then return either the innerHTML or value
    if ($useInnerHtml)
    {
        return $control.innerHTML
    }

    return $control.value
}


function Write-MonocleHost($message, $session, [switch]$noTab)
{
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


function Write-MonocleInfo($message, $session)
{
    if ($session -ne $null -and $session.Info -and !$session.Quiet)
    {
        Write-Host "INFO: $message" -ForegroundColor Yellow
    }
}


function Write-MonocleError($message, $session, [switch]$noTab)
{
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


function Test-Url($url)
{
    # Truncate the URL of any query parameters
    $url = ([System.Uri]$url).GetLeftPart([System.UriPartial]::Path)

    # Initial code setting as success
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
        
        # If the exception doesn't contain a Response, then either the
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

    # Anything that is 1xx-2xx is normally successful, anything that's
    # 300+ is normally always a failure to load
    # -1 is a fatal error (SSL, invalid host, etc)
    if ($code -eq -1 -or $code -ge 300)
    {
        throw "Failed to load URL: '$url'`nStatus: $code`nMessage: $message"
    }

    return $code
}


function Test-MonocleSession()
{
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
}


function Set-IEFocus($session)
{
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


function Invoke-Screenshot($session, $screenshotName, $screenshotPath, $initialVisibleState)
{
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


#Export-ModuleMember -Function InMonocleSession, NavigateTo