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
        [ValidateSet('Id', 'Tag', 'MPath')]
        [string]
        $FilterType,

        [Parameter()]
        [string]
        $Id,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [Parameter()]
        [string]
        $AttributeValue,

        [Parameter()]
        [string]
        $ElementValue,

        [Parameter()]
        [string]
        $MPath,

        [switch]
        $NoThrow
    )

    switch ($FilterType.ToLowerInvariant()) {
        'id' {
            return (Get-MonocleElementById -Id $Id -NoThrow:$NoThrow)
        }

        'tag' {
            if ([string]::IsNullOrWhiteSpace($AttributeName)) {
                return (Get-MonocleElementByTagName -TagName $TagName -ElementValue $ElementValue -NoThrow:$NoThrow)
            }
            else {
                return (Get-MonocleElementByTagName -TagName $TagName -AttributeName $AttributeName -AttributeValue $AttributeValue -ElementValue $ElementValue -NoThrow:$NoThrow)
            }
        }

        'mpath' {
            return (Get-MonocleElementByMPath -MPath $MPath -NoThrow:$NoThrow)
        }
    }
}

function Get-MonocleElementById
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [switch]
        $NoThrow
    )

    $document = $Browser.Document

    Write-Verbose -Message "Finding element with identifier '$Id'"
    $element = $document.IHTMLDocument3_getElementById($Id)

    # if no element by ID, try by first named element
    if (Test-MonocleElementNull -Element $element) {
        Write-Verbose -Message "Finding element with name '$Id'"
        $element = $document.IHTMLDocument3_getElementsByName($Id) | Select-Object -First 1
    }

    # throw error if can't find element
    if ((Test-MonocleElementNull -Element $element) -and !$NoThrow) {
        throw "Element with ID/Name of '$Id' not found"
    }

    return @{
        Element = $element
        Id = "<$($Id)>"
    }
}

function Get-MonocleElementByTagName
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $TagName,

        [Parameter(Mandatory=$true, ParameterSetName='Attribute')]
        [string]
        $AttributeName,

        [Parameter(Mandatory=$true, ParameterSetName='Attribute')]
        [string]
        $AttributeValue,

        [Parameter()]
        [string]
        $ElementValue,

        [switch]
        $NoThrow
    )

    $document = $Browser.Document

    # get all elements for the tag
    $elements = $document.IHTMLDocument3_getElementsByTagName($TagName)
    $id = $TagName.ToLowerInvariant()

    # if we have attribute info, attempt to get an element
    if ($PSCmdlet.ParameterSetName -ieq 'Attribute')
    {
        Write-Verbose -Message "Finding element with tag <$TagName>, attribute '$AttributeName' with value '$AttributeValue'"

        $elements = $elements |
            Where-Object { $_.getAttribute($AttributeName) -imatch $AttributeValue }

        # throw error if can't find element
        if ((Test-MonocleElementNull -Element ($elements | Select-Object -First 1)) -and !$NoThrow) {
            throw "Element <$TagName> with attribute '$AttributeName' and value of '$AttributeValue' not found"
        }

        $id += "[$($AttributeName)=$($AttributeValue)]"
    }

    if (![string]::IsNullOrWhiteSpace($ElementValue))
    {
        Write-Verbose -Message "Finding element with tag <$TagName>, and value '$ElementValue'"

        $element = $elements |
            Where-Object { $_.value -imatch $ElementValue }
            Select-Object -First 1

        if (Test-MonocleElementNull -Element $element) {
            $element = $elements |
                Where-Object { $_.innerHTML -imatch $ElementValue }
                Select-Object -First 1
        }

        # throw error if can't find element
        if ((Test-MonocleElementNull -Element $element) -and !$noThrow) {
            throw "Element <$TagName> with value of '$ElementValue' not found"
        }

        $id += "=$($ElementValue)"
    }
    else {
        $element = ($elements | Select-Object -First 1)
    }

    return @{
        Element = $element
        Id = "<$($id)>"
    }
}

function Get-MonocleElementByMPath
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $MPath,

        [switch]
        $NoThrow
    )

    $element = Resolve-MonocleMPath -MPath $MPath

    # throw error if can't find element
    if ((Test-MonocleElementNull -Element $element) -and !$NoThrow) {
        throw "Cannot find any element based on the MPath supplied: $MPath"
    }

    return @{
        Element = $element
        Id = "<$($MPath)>"
    }
}