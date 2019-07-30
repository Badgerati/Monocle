function Test-ControlNull
{
    param (
        $control
    )

    return $control -eq $null -or $control -eq [System.DBNull]::Value
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