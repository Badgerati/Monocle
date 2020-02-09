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

    if ([string]::IsNullOrWhiteSpace($Element.TagName)) {
        return
    }

    Set-MonocleElementAttribute -Element $Element -Name 'meta-monocle-id' -Value $Id
}

function Get-MonocleElementInternal
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Id', 'Tag', 'XPath', 'Selector')]
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

        [Parameter()]
        [string]
        $Selector,

        [Parameter()]
        [int]
        $Timeout = 0,

        [switch]
        $NoThrow,

        [switch]
        $All
    )

    if ($Timeout -le 0) {
        $Timeout = Get-MonocleTimeout
    }

    $seconds = 0

    while ($true) {
        try {
            switch ($FilterType.ToLowerInvariant()) {
                'id' {
                    return (Get-MonocleElementById -Id $Id -NoThrow:$NoThrow -All:$All)
                }

                'tag' {
                    if ([string]::IsNullOrWhiteSpace($AttributeName)) {
                        return (Get-MonocleElementByTagName -TagName $TagName -ElementValue $ElementValue -NoThrow:$NoThrow -All:$All)
                    }
                    else {
                        return (Get-MonocleElementByTagName -TagName $TagName -AttributeName $AttributeName -AttributeValue $AttributeValue -ElementValue $ElementValue -NoThrow:$NoThrow -All:$All)
                    }
                }

                'xpath' {
                    return (Get-MonocleElementByXPath -XPath $XPath -NoThrow:$NoThrow -All:$All)
                }

                'selector' {
                    return (Get-MonocleElementBySelector -Selector $Selector -NoThrow:$NoThrow -All:$All)
                }
            }
        }
        catch {
            $seconds++

            if ($seconds -ge $Timeout) {
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
        $NoThrow,

        [switch]
        $All
    )

    Write-Verbose -Message "Finding element with identifier '$Id'"
    $element = $Browser.FindElementsById($Id)

    # if no element by ID, try by first named element
    if ($null -eq ($element | Select-Object -First 1)) {
        Write-Verbose -Message "Finding element with name '$Id'"
        $element = $Browser.FindElementsByName($Id)
    }

    # throw error if can't find element
    if (($null -eq ($element | Select-Object -First 1)) -and !$NoThrow) {
        throw "Element with ID/Name of '$Id' not found"
    }

    # one or all elements?
    if (!$All) {
        $element = $element | Select-Object -First 1
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

        [Parameter(ParameterSetName='Attribute')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Attribute')]
        [string]
        $AttributeValue,

        [Parameter()]
        [string]
        $ElementValue,

        [switch]
        $NoThrow,

        [switch]
        $All
    )

    # get all elements for the tag
    Write-Verbose -Message "Finding element with tag <$TagName>"
    $element = $Browser.FindElementsByTagName($TagName)
    $id = $TagName.ToLowerInvariant()

    # if we have attribute info, attempt to get an element
    if (($PSCmdlet.ParameterSetName -ieq 'Attribute') -and ![string]::IsNullOrWhiteSpace($AttributeName))
    {
        Write-Verbose -Message "Filtering $($element.Length) elements by attribute '$AttributeName' with value '$AttributeValue'"
        $found = $false
        $justFirst = [string]::IsNullOrWhiteSpace($ElementValue)

        # find elements with the correct attribue name/value
        $element = @(foreach ($_element in $element) {
            if ($_element.GetAttribute($AttributeName) -inotmatch $AttributeValue) {
                continue
            }

            $found = $true
            $_element

            if ($found -and $justFirst) {
                break
            }
        })

        # throw error if can't find element
        if (($null -eq ($element | Select-Object -First 1)) -and !$NoThrow) {
            throw "Element <$TagName> with attribute '$AttributeName' and value of '$AttributeValue' not found"
        }

        $id += "[@$($AttributeName)=$($AttributeValue)]"
    }

    if (![string]::IsNullOrWhiteSpace($ElementValue))
    {
        Write-Verbose -Message "Filtering $($element.Length) elements with tag <$TagName>, and value '$ElementValue'"

        $element = $element | Where-Object { $_.Text -imatch $ElementValue }

        # throw error if can't find element
        if (($null -eq ($element | Select-Object -First 1)) -and !$NoThrow) {
            throw "Element <$TagName> with value of '$ElementValue' not found"
        }

        $id += "=$($ElementValue)"
    }

    # one or all elements?
    if (!$All) {
        $element = $element | Select-Object -First 1
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
        $NoThrow,

        [switch]
        $All
    )

    Write-Verbose -Message "Finding element with XPath '$XPath'"
    $element = @($Browser.FindElementsByXPath($XPath))

    # throw error if can't find element
    if (($null -eq ($element | Select-Object -First 1)) -and !$NoThrow) {
        throw "Element with XPath of '$XPath' not found"
    }

    # one or all elements?
    if (!$All) {
        $element = $element | Select-Object -First 1
    }

    return @{
        Element = $element
        Id = "<$($XPath)>"
    }
}

function Get-MonocleElementBySelector
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Selector,

        [switch]
        $NoThrow,

        [switch]
        $All
    )

    Write-Verbose -Message "Finding element with selector '$Selector'"
    if ($All) {
        $element = Invoke-MonocleJavaScript -Script 'return document.querySelectorAll(arguments[0])' -Arguments $Selector
    }
    else {
        $element = Invoke-MonocleJavaScript -Script 'return document.querySelector(arguments[0])' -Arguments $Selector
    }

    # throw error if can't find element
    if (($null -eq ($element | Select-Object -First 1)) -and !$NoThrow) {
        throw "Element with selector of '$Selector' not found"
    }

    return @{
        Element = $element
        Id = "<$($Selector)>"
    }
}