function Test-MonocleElementNull
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $Element
    )

    return (($null -eq $Element) -or ($Element -eq [System.DBNull]::Value))
}

function Get-MonocleElement
{
    [CmdletBinding()]
    param (
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

    $document = $Browser.Document

    # if it's set, find element based on mpath
    if ($MPath -and ![string]::IsNullOrWhiteSpace($Name))
    {
        $element = Resolve-MonocleMPath -MPath $Name

        # throw error if can't find element
        if ((Test-MonocleElementNull -Element $element) -and !$NoThrow) {
            throw "Cannot find any element based on the MPath supplied: $Name"
        }

        return $element
    }

    # if they're set, retrieve element by tag/attribute value combo
    if (![string]::IsNullOrWhiteSpace($TagName) -and ![string]::IsNullOrWhiteSpace($AttributeName))
    {
        Write-Verbose -Message "Finding element with tag <$TagName>, attribute '$AttributeName' and value '$Name'"

        $element = $document.IHTMLDocument3_getElementsByTagName($TagName) |
            Where-Object { $_.getAttribute($AttributeName) -imatch $Name } |
            Select-Object -First 1

        # throw error if can't find element
        if ((Test-MonocleElementNull -Element $element) -and !$NoThrow) {
            throw "Element <$TagName> with attribute '$AttributeName' value of $Name not found."
        }

        return $element
    }

    # if they're set, retrieve the element by tag/value combo (value then innerHTML)
    if (![string]::IsNullOrWhiteSpace($TagName) -and $FindByValue)
    {
        Write-Verbose -Message "Finding element with tag <$TagName>, and value '$Name'"
        $elements = $document.IHTMLDocument3_getElementsByTagName($TagName)

        $element = $elements |
            Where-Object { $_.value -ieq $Name }
            Select-Object -First 1
        
        if (Test-MonocleElementNull -Element $element) {
            $element = $elements |
                Where-Object { $_.innerHTML -ieq $Name }
                Select-Object -First 1
        }
        
        # throw error if can't find element
        if ((Test-MonocleElementNull -Element $element) -and !$noThrow) {
            throw "Element <$TagName> with value of $Name not found."
        }

        return $element
    }

    # if no tag/attr combo, attempt to retrieve by ID
    Write-Verbose -Message "Finding element with identifier '$Name'"
    $element = $document.IHTMLDocument3_getElementById($Name)

    # if no element by ID, try by first named element
    if (Test-MonocleElementNull -Element $element) {
        Write-Verbose -Message "Finding element with name '$Name'"
        $element = $document.IHTMLDocument3_getElementsByName($Name) | Select-Object -First 1
    }

    # throw error if can't find element
    if ((Test-MonocleElementNull -Element $element) -and !$NoThrow) {
        throw "Element with ID/Name of $Name not found."
    }

    return $element
}