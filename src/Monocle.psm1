

$root = Split-Path -Path $MyInvocation.MyCommand.Path
Get-ChildItem "$root\Functions\*.ps1" |
    Resolve-Path |
    ForEach-Object { . $_ }


function SleepWhileBusy($session)
{
    while ($session.Browser.Busy) { Start-Sleep -Seconds 1 }
}


function IsControlNull($control)
{
    return $control -eq $null -or $control -eq [System.DBNull]::Value
}


function GetControl($session, $name, $tagName = $null, $attributeName = $null)
{
    $document = $session.Browser.Document

    # If they're set, retrieve control by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($tagName) -and ![string]::IsNullOrWhiteSpace($attributeName))
    {
        Write-MonocleHost "Finding control with tag <$tagName>, attribute '$attributeName' and value '$name'" $session

        $control = $document.getElementsByTagName($tagName) |
            Where-Object { $_.$attributeName -ne $null -and $_.$attributeName.StartsWith($name) }
            Select-Object -First 1
        
        # Throw error if can't find control
        if (IsControlNull $control)
        {
            throw "Element <$tagName> with attribute '$attributeName' value of $name not found."
        }

        return $control
    }

    # If no tag/attr combo, attempt to retrieve by ID
    Write-MonocleHost "Finding control with identifier '$name'" $session
    $control = $document.getElementById($name)

    # If no control by ID, try by first named control
    if (IsControlNull $control)
    {
        Write-MonocleHost "Finding control with name '$name'" $session
        $control = $document.getElementsByName($name) | Select-Object -First 1
    }

    # Throw error if can't find control
    if (IsControlNull $control)
    {
        throw "Element with ID/Name of $name not found."
    }

    return $control
}


function GetControlValue($control, [switch]$useInnerHtml)
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


function Write-MonocleHost($message, $session)
{
    if ($session -ne $null -and !$session.Quiet)
    {
        Write-Host $message
    }
}

function Write-MonocleError($message, $session)
{
    Write-Host $message -ForegroundColor Red
}


function Test-Url($url)
{
    $code = 200

    try
    {
        $result = Invoke-WebRequest -Uri $url -TimeoutSec 30

        # If the header contains a closed connection, then it will be a redirect
        # from a 404 page. Such as from BT.
        if ($result.Headers['Connection'] -ieq 'closed')
        {
            $code = 404
        }
        else
        {
            $code = [int]$result.StatusCode
        }
    }
    catch [System.Net.WebException]
    {
        $ex = $_.Exception
        
        # If the URL just doesn't exist then there is no status code.
        # If the message is as below, then it's technically a 404
        if ($ex.Message -imatch 'The remote name could not be resolved')
        {
            $code = 404
        }
        else
        {
            $code = $ex.Response.StatusCode.Value__
        }
    }

    # Anything that is 1xx-2xx is normally successful, anything that's
    # 300+ is normally always a failure to load
    if ($code -ge 300)
    {
        throw "Failed to load URL: '$url'"
    }

    return $code
}


#Export-ModuleMember -Function InMonocleSession, NavigateTo