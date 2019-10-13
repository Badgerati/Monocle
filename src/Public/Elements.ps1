function Set-MonocleElementValue
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

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
        $XPath,

        [switch]
        $Mask
    )

    # Attempt to retrieve an appropriate element
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    if ($Mask) {
        Write-MonocleHost -Message "Setting $($result.Id) element value to: ********"
    }
    else {
        Write-MonocleHost -Message "Setting $($result.Id) element value to: $Value"
    }

    # Set the value of the element, if it's a select element, set the appropriate option with value to be selected
    if ($result.Element.Length -gt 1 -and $result.Element[0].TagName -ieq 'option') {
        $element = ($result.Element | Where-Object { $_.Text -ieq $Value })
        $element.Click() | Out-Null
    }
    else {

        $result.Element.SendKeys($Value)
    }
}

function Get-MonocleElementValue
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([string])]
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

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    # get the value of the element, if it's a select element, get the appropriate option where option is selected
    if (($result.Element.Length -gt 1) -and ($result.Element[0].TagName -ieq 'option')) {
        return ($result.Element | Where-Object { $_.Selected -eq $true }).Text
    }

    # if not a select element, then return the value
    return $result.Element.Text
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

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath `
        -NoThrow

    return ($null -ne $result.Element)
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
        $Pattern,

        [Parameter()]
        [int]
        $AttemptCount = 10
    )

    $count = 0

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
    {
        'pattern' {
            Write-MonocleHost -Message "Waiting for value to match pattern: $Pattern"

            while ($Browser.PageSource -inotmatch $Pattern) {
                if ($count -ge $AttemptCount) {
                    throw "Expected value to match pattern: $($Pattern)`nBut found nothing`nOn: $(Get-MonocleUrl)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }

        'value' {
            Write-MonocleHost -Message "Waiting for value: $Value"

            while ($Browser.PageSource -ine $Value) {
                if ($count -ge $AttemptCount) {
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

function Wait-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
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
        $XPath,

        [Parameter()]
        [int]
        $AttemptCount = 10
    )

    $count = 0
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath `
        -NoThrow

    Write-MonocleHost -Message "Waiting for element: $($result.Id)"

    while ($null -eq $result.Element) {
        if ($count -ge $AttemptCount) {
            throw "Expected element: $($result.Id)`nBut found nothing`nOn: $(Get-MonocleUrl)"
        }

        $result = Get-MonocleElement `
            -FilterType $PSCmdlet.ParameterSetName `
            -Id $Id `
            -TagName $TagName `
            -AttributeName $AttributeName `
            -AttributeValue $AttributeValue `
            -ElementValue $ElementValue `
            -XPath $XPath `
            -NoThrow

        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost -Message "Expected element loaded after $count second(s)"
}

function Invoke-MonocleElementClick
{
    [CmdletBinding(DefaultParameterSetName='Id')]
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
        $XPath,

        [Parameter()]
        [int]
        $Duration = 10,

        [switch]
        $WaitUrl
    )

    # get the element to click
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    Write-MonocleHost -Message "Clicking element: $($result.Id)"

    $url = Get-MonocleUrl
    $result.Element.Click() | Out-Null
    Start-MonocleSleepWhileBusy

    # check if we should wait until the url is different
    if ($WaitUrl) {
        Wait-MonocleUrlDifferent -CurrentUrl $url -Duration $Duration
    }
}

function Invoke-MonocleElementCheck
{
    [CmdletBinding(DefaultParameterSetName='Id')]
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
        $XPath,

        [switch]
        $Uncheck
    )

    # Attempt to retrieve an appropriate element
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $($result.Id)"
        if ($result.Element.Selected) {
            $result.Element.Click() | Out-Null
        }
    }
    else {
        Write-MonocleHost -Message "Checking element: $($result.Id)"
        if (!$result.Element.Selected) {
            $result.Element.Click() | Out-Null
        }
    }

    Start-MonocleSleepWhileBusy
}