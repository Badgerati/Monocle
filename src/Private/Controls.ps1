function Test-ControlNull
{
    param (
        [Parameter()]
        $Control
    )

    return (($null -eq $Control) -or ($Control -eq [System.DBNull]::Value))
}

function Get-Control
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $Session,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $TagName = $null,
        
        [Parameter()]
        [string]
        $AttributeName = $null,

        [switch]
        $FindByValue,

        [switch]
        $NoThrow,

        [switch]
        $MPath
    )

    $document = $Session.Browser.Document

    # if it's set, find control based on mpath
    if ($MPath -and ![string]::IsNullOrWhiteSpace($Name))
    {
        $control = Resolve-MPath -Session $Session -MPath $Name

        # throw error if can't find control
        if ((Test-ControlNull $Control) -and !$NoThrow) {
            throw "Cannot find any element based on the MPath supplied: $Name"
        }

        return $control
    }

    # if they're set, retrieve control by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($TagName) -and ![string]::IsNullOrWhiteSpace($AttributeName))
    {
        Write-MonocleInfo "Finding control with tag <$TagName>, attribute '$AttributeName' and value '$Name'" $Session

        $control = $document.getElementsByTagName($TagName) |
            Where-Object { $_.getAttribute($AttributeName) -imatch $Name } |
            Select-Object -First 1

        # throw error if can't find control
        if ((Test-ControlNull $control) -and !$NoThrow) {
            throw "Element <$TagName> with attribute '$AttributeName' value of $Name not found."
        }

        return $control
    }

    # if they're set, retrieve the control by tag/value combo (value then innerHTML)
    if (![string]::IsNullOrWhiteSpace($TagName) -and $FindByValue)
    {
        Write-MonocleInfo "Finding control with tag <$TagName>, and value '$Name'" $Session

        $controls = $document.getElementsByTagName($TagName)

        $control = $controls |
            Where-Object { $_.value -ieq $Name }
            Select-Object -First 1
        
        if (Test-ControlNull $control) {
            $control = $controls |
                Where-Object { $_.innerHTML -ieq $Name }
                Select-Object -First 1
        }
        
        # throw error if can't find control
        if ((Test-ControlNull $control) -and !$noThrow) {
            throw "Element <$TagName> with value of $Name not found."
        }

        return $control
    }

    # if no tag/attr combo, attempt to retrieve by ID
    Write-MonocleInfo "Finding control with identifier '$Name'" $Session
    $control = $document.getElementById($Name)

    # if no control by ID, try by first named control
    if (Test-ControlNull $control) {
        Write-MonocleInfo "Finding control with name '$Name'" $Session
        $control = $document.getElementsByName($Name) | Select-Object -First 1
    }

    # throw error if can't find control
    if ((Test-ControlNull $control) -and !$NoThrow) {
        throw "Element with ID/Name of $Name not found."
    }

    return $control
}

function Get-ControlValue
{
    param (
        [Parameter()]
        $Control,

        [switch]
        $UseInnerHtml
    )

    # get the value of the control, if it's a select control, get the appropriate
    # option where option is selected
    if ($Control.Length -gt 1 -and $Control[0].tagName -ieq 'option')
    {
        return ($Control | Where-Object { $_.Selected -eq $true }).innerHTML
    }

    # if not a select control, then return either the innerHTML or value
    if ($UseInnerHtml) {
        return $Control.innerHTML
    }

    return $Control.value
}