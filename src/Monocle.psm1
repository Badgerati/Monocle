

$root = Split-Path -Path $MyInvocation.MyCommand.Path
Get-ChildItem "$root\Functions\*.ps1" |
    Resolve-Path |
    ForEach-Object { . $_ }


function SleepWhileBusy($session)
{
    while ($session.Busy) { Start-Sleep -Seconds 1 }
}


function IsControlNull($control)
{
    return $control -eq $null -or $control -eq [System.DBNull]::Value
}


function GetControl($session, $name, $tagName = $null, $attributeName = $null)
{
    $document = $session.Document

    # If they're set, retrieve control by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($tagName) -and ![string]::IsNullOrWhiteSpace($attributeName))
    {
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
    $control = $document.getElementById($name)

    # If no control by ID, try by first named control
    if (IsControlNull $control)
    {
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
    if ($useInnerHtml)
    {
        return $control.innerHTML
    }

    return $control.value
}


#Export-ModuleMember -Function InMonocleSession, NavigateTo