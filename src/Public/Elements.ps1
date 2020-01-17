function Set-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $Mask,

        [switch]
        $NoClear
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    if ($Mask) {
        Write-MonocleHost -Message "Setting $($id) element value to: ********"
    }
    else {
        Write-MonocleHost -Message "Setting $($id) element value to: $Value"
    }

    # set the value of the element
    if (!$NoClear) {
        $Element.Clear()
    }

    $Element.SendKeys($Value)
}

function Clear-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Clearing $($id) element value"

    # clear the value of the element
    $Element.Clear()
}

function Get-MonocleElementAttribute
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return $Element.GetAttribute($Name)
}

function Test-MonocleElementAttribute
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    try {
        return ($null -ne (Get-MonocleElementAttribute -Element $Element -Name $Name))
    }
    catch {
        return $false
    }
}

function Set-MonocleElementAttribute
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].setAttribute(arguments[1], arguments[2])' -Arguments $Element, $Name, $Value | Out-Null
}

function Submit-MonocleForm
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $WaitUrl
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Submitting form block: $($id)"

    $url = Get-MonocleUrl
    $Element.Submit() | Out-Null
    Start-MonocleSleepWhileBusy

    # check if we should wait until the url is different
    if ($WaitUrl) {
        Wait-MonocleUrlDifferent -FromUrl $url
    }
}

function Get-MonocleElementValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $Mask
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    # get the value of the element
    $value = $Element.Text

    if ($Mask) {
        Write-MonocleHost -Message "Value of $($id) element: ********"
    }
    else {
        Write-MonocleHost -Message "Value of $($id) element: $value"
    }

    return $value
}

function Test-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath
    )

    $result = $null

    try {
        $result = Get-MonocleElementInternal `
            -FilterType $PSCmdlet.ParameterSetName `
            -Id $Id `
            -TagName $TagName `
            -AttributeName $AttributeName `
            -AttributeValue $AttributeValue `
            -ElementValue $ElementValue `
            -XPath $XPath
    }
    catch { }

    return (($null -ne $result) -and ($null -ne $result.Element))
}

function Get-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([OpenQA.Selenium.IWebElement])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath
    )

    # attempt to get the monocle element
    $result = Get-MonocleElementInternal `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    # set the meta id on the element
    Set-MonocleElementId -Element $result.Element -Id $result.Id

    # return the element
    return $result.Element
}

function Wait-MonocleValue
{
    [CmdletBinding(DefaultParameterSetName='Value')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Value')]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Pattern')]
        [string]
        $Pattern
    )

    $count = 0
    $timeout = Get-MonocleTimeout

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
    {
        'pattern' {
            Write-MonocleHost -Message "Waiting for value to match pattern: $Pattern"

            while ($Browser.PageSource -inotmatch $Pattern) {
                if ($count -ge $timeout) {
                    throw "Expected value to match pattern: $($Pattern)`nBut found nothing`nOn: $(Get-MonocleUrl)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }

        'value' {
            Write-MonocleHost -Message "Waiting for value: $Value"

            while ($Browser.PageSource -ine $Value) {
                if ($count -ge $timeout) {
                    throw "Expected value: $($Value)`nBut found nothing`nOn: $(Get-MonocleUrl)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }
    }

    Write-MonocleHost -Message "Expected value loaded after $count second(s)"
    Start-MonocleSleepWhileBusy
}

function Invoke-MonocleElementClick
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $WaitUrl
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Clicking element: $($id)"

    $url = Get-MonocleUrl

    # attempt to click the element, if it fails for "another element would receive" then try clikcing use javascript
    try {
        $Element.Click() | Out-Null
    }
    catch {
        if ($_.Exception.Message -ilike '*other element would receive the click*') {
            Invoke-MonocleJavaScript -Script 'arguments[0].click()' -Arguments $Element | Out-Null
        }
    }

    Start-MonocleSleepWhileBusy

    # check if we should wait until the url is different
    if ($WaitUrl) {
        Wait-MonocleUrlDifferent -FromUrl $url
    }
}

function Invoke-MonocleElementCheck
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $Uncheck
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $($id)"
        if ($Element.Selected) {
            $Element.Click() | Out-Null
        }
    }
    else {
        Write-MonocleHost -Message "Checking element: $($id)"
        if (!$Element.Selected) {
            $Element.Click() | Out-Null
        }
    }

    Start-MonocleSleepWhileBusy
}
