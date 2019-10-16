function Get-MonocleElementId
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    return (Get-MonocleElementAttribute -Element $Element -Name 'meta-monocle-id')
}

function Set-MonocleElementId
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Id
    )

    return (Set-MonocleElementAttribute -Element $Element -Name 'meta-monocle-id' -Value $Id)
}

function Get-MonocleElementInternal
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Id', 'Tag', 'XPath')]
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
        $XPath,

        [switch]
        $NoThrow
    )

    $timeout = Get-MonocleTimeout
    $seconds = 0

    while ($true) {
        try {
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

                'xpath' {
                    return (Get-MonocleElementByXPath -XPath $XPath -NoThrow:$NoThrow)
                }
            }
        }
        catch {
            $seconds++

            if ($seconds -ge $timeout) {
                throw $_.Exception
            }

            Start-Sleep -Seconds 1
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

    Write-Verbose -Message "Finding element with identifier '$Id'"
    $element = $Browser.FindElementsById($Id) | Select-Object -First 1

    # if no element by ID, try by first named element
    if ($null -eq $element) {
        Write-Verbose -Message "Finding element with name '$Id'"
        $element = $Browser.FindElementsByName($Id) | Select-Object -First 1
    }

    # throw error if can't find element
    if (($null -eq $element) -and !$NoThrow) {
        throw "Element with ID/Name of '$Id' not found"
    }

    return @{
        Element = $element
        Id = "<[@id=$($Id)]>"
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

    # get all elements for the tag
    Write-Verbose -Message "Finding element with tag <$TagName>"
    $elements = $Browser.FindElementsByTagName($TagName)
    $id = $TagName.ToLowerInvariant()

    # if we have attribute info, attempt to get an element
    if ($PSCmdlet.ParameterSetName -ieq 'Attribute')
    {
        Write-Verbose -Message "Filtering $($elements.Length) elements by attribute '$AttributeName' with value '$AttributeValue'"
        $found = $false
        $justFirst = [string]::IsNullOrWhiteSpace($ElementValue)

        # find elements with the correct attribue name/value
        $elements = @(foreach ($element in $elements) {
            if ($element.GetAttribute($AttributeName) -inotmatch $AttributeValue) {
                continue
            }

            $found = $true
            $element

            if ($found -and $justFirst) {
                break
            }
        })

        # throw error if can't find element
        if (($null -eq ($elements | Select-Object -First 1)) -and !$NoThrow) {
            throw "Element <$TagName> with attribute '$AttributeName' and value of '$AttributeValue' not found"
        }

        $id += "[@$($AttributeName)=$($AttributeValue)]"
    }

    if (![string]::IsNullOrWhiteSpace($ElementValue))
    {
        Write-Verbose -Message "Filtering $($elements.Length) elements with tag <$TagName>, and value '$ElementValue'"

        $element = $elements |
            Where-Object { $_.Text -imatch $ElementValue }
            Select-Object -First 1

        # throw error if can't find element
        if (($null -eq $element) -and !$noThrow) {
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

function Get-MonocleElementByXPath
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $XPath,

        [switch]
        $NoThrow
    )

    Write-Verbose -Message "Finding element with XPath '$XPath'"
    $element = @($Browser.FindElementsByXPath($XPath)) | Select-Object -First 1

    # throw error if can't find element
    if (($null -eq $element) -and !$NoThrow) {
        throw "Element with XPath of '$XPath' not found"
    }

    return @{
        Element = $element
        Id = "<$($XPath)>"
    }
}