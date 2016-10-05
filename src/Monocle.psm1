

$root = Split-Path -Path $MyInvocation.MyCommand.Path
Get-ChildItem "$root\Functions\*.ps1" |
    Resolve-Path |
    ForEach-Object { . $_ }

Get-ChildItem "$root\Assertions\*.ps1" |
    Resolve-Path |
    ForEach-Object { . $_ }


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


function Test-ControlNull
{
    param (
        $control
    )

    return $control -eq $null -or $control -eq [System.DBNull]::Value
}


function Resolve-MPathExpression #($expr, $document = $null, $controls = $null)
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $expr,
        
        [Parameter(Mandatory=$false)]
        $document = $null,
        
        [Parameter(Mandatory=$false)]
        $controls = $null
    )

    # Regex to match an individual mpath expression
    $regex = '^(?<tag>[a-zA-Z]+)(?<filter>\[(?<attr>\@[a-zA-Z\-]+|\d+)((?<opr>(\!){0,1}(\=|\~))(?<value>.+?)){0,1}\](\[(?<index>\d+)\]){0,1}){0,1}$'
    $foundControls = $null

    # ensure the expression is valid against the regex
    if ($expr -match $regex)
    {
        $tag = $Matches['tag']
        
        # find initial controls based on the tag from document or previously found controls
        if ($document -ne $null)
        {
            $foundControls = $document.getElementsByTagName($tag)
        }
        else
        {
            $foundControls = $controls | ForEach-Object { $_.getElementsByTagName($tag) }
        }

        # if there's a filter, then filter down the found controls above
        if (![string]::IsNullOrWhiteSpace($Matches['filter']))
        {
            $attr = $Matches['attr']
            $opr = $Matches['opr']
            $value = $Matches['value']
            $index = $Matches['index']

            # filtering by attributes starts with an '@', else we have an index into the controls
            if ($attr.StartsWith('@'))
            {
                $attr = $attr.Trim('@')

                # if there's no operator, then use all controls that have a non-empty attribute
                if ([string]::IsNullOrWhiteSpace($opr))
                {
                    $foundControls = $foundControls | Where-Object { ![string]::IsNullOrWhiteSpace($_.getAttribute($attr)) }
                }
                else
                {
                    # find controls based on validaity of attribute to passed value
                    switch ($opr)
                    {
                        '='
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -ieq $value }
                        }

                        '~'
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -imatch $value }
                        }

                        '!='
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -ine $value }
                        }

                        '!~'
                        {
                            $foundControls = $foundControls | Where-Object { $_.getAttribute($attr) -inotmatch $value }
                        }
                    }
                }

                # select a control from the filtered controls based on index (could sometimes happen)
                if (![string]::IsNullOrWhiteSpace($index))
                {
                    $foundControls = $foundControls | Select-Object -Skip ([int]$index) -First 1
                }
            }
            else
            {
                # select the control based on index of found controls
                $foundControls = $foundControls | Select-Object -Skip ([int]$attr) -First 1
            }
        }
    }
    else
    {
        throw "MPath expression is not valid: $expr"
    }

    return $foundControls
}


function Resolve-MPath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $mpath
    )

    # split into multiple expressions
    $exprs = $mpath -split '/'

    # if there are no expression, return null
    if ($exprs -eq $null -or $exprs.length -eq 0)
    {
        return [System.DBNull]::Value
    }

    # find initial controls based on the document and first expression
    $controls = Resolve-MPathExpression $exprs[0] -document $session.Browser.Document

    # find rest of controls from the previous controls found above
    for ($i = 1; $i -lt $exprs.length; $i++)
    {
        $controls = Resolve-MPathExpression $exprs[$i] -controls $controls
    }

    # Monocle only deals with single controls, so return the first
    return ($controls | Select-Object -First 1)
}


function Get-Control
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $session,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $name,

        [Parameter(Mandatory=$false)]
        [string] $tagName = $null,
        
        [Parameter(Mandatory=$false)]
        [string] $attributeName = $null,

        [switch] $findByValue,
        [switch] $noThrow,
        [switch] $mpath
    )

    $document = $session.Browser.Document

    # if it's set, find control based on mpath
    if ($mpath -and ![string]::IsNullOrWhiteSpace($name))
    {
        $control = Resolve-MPath $session $name

        # throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow)
        {
            throw "Cannot find any element based on the MPath supplied: $name"
        }

        return $control
    }

    # if they're set, retrieve control by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($tagName) -and ![string]::IsNullOrWhiteSpace($attributeName))
    {
        Write-MonocleInfo "Finding control with tag <$tagName>, attribute '$attributeName' and value '$name'" $session

        $control = $document.getElementsByTagName($tagName) |
            Where-Object { $_.getAttribute($attributeName) -imatch $name } |
            Select-Object -First 1

        # throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow)
        {
            throw "Element <$tagName> with attribute '$attributeName' value of $name not found."
        }

        return $control
    }

    # if they're set, retrieve the control by tag/value combo (value then innerHTML)
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
        
        # throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow)
        {
            throw "Element <$tagName> with value of $name not found."
        }

        return $control
    }

    # if no tag/attr combo, attempt to retrieve by ID
    Write-MonocleInfo "Finding control with identifier '$name'" $session
    $control = $document.getElementById($name)

    # if no control by ID, try by first named control
    if (Test-ControlNull $control)
    {
        Write-MonocleInfo "Finding control with name '$name'" $session
        $control = $document.getElementsByName($name) | Select-Object -First 1
    }

    # throw error if can't find control
    if ((Test-ControlNull $control) -and !$noThrow)
    {
        throw "Element with ID/Name of $name not found."
    }

    return $control
}


function Get-ControlValue
{
    param (
        $control,
        [switch] $useInnerHtml
    )

    # get the value of the control, if it's a select control, get the appropriate
    # option where option is selected
    if ($control.Length -gt 1 -and $control[0].tagName -ieq 'option')
    {
        return ($control | Where-Object { $_.Selected -eq $true }).innerHTML
    }

    # if not a select control, then return either the innerHTML or value
    if ($useInnerHtml)
    {
        return $control.innerHTML
    }

    return $control.value
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


$exportFunctions = @(
    'Assert-BodyValue',
    'Assert-ElementValue',
    'CheckElement',
    'ClickElement',
    'DownloadImage',
    'ExpectElement',
    'ExpectUrl',
    'ExpectValue',
    'GetElementValue',
    'InMonocleSession',
    'ModifyUrl',
    'NavigateTo',
    'Screenshot',
    'SetElementValue',
    'SleepBrowser'
)

Export-ModuleMember -Function $exportFunctions