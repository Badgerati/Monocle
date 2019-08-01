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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

        [switch]
        $Mask
    )

    # Attempt to retrieve an appropriate element
    $element = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    if ($Mask) {
        Write-MonocleHost -Message "Setting $($element.tagName) element value to: ********"
    }
    else {
        Write-MonocleHost -Message "Setting $($element.tagName) element value to: $Value"
    }

    # Set the value of the element, if it's a select element, set the appropriate option with value to be selected
    if ($element.Length -gt 1 -and $element[0].tagName -ieq 'option') {
        ($element | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else {
        $element.value = $Value
    }
}

function Get-MonocleElementValue
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

        [switch]
        $UseInnerHtml
    )

    $element = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    # get the value of the element, if it's a select element, get the appropriate option where option is selected
    if (($element.Length -gt 1) -and ($element[0].tagName -ieq 'option')) {
        return ($element | Where-Object { $_.Selected -eq $true }).innerHTML
    }

    # if not a select element, then return either the innerHTML or value
    if ($UseInnerHtml) {
        return $element.innerHTML
    }

    return $element.value
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

            while ($Browser.Document.body.outerHTML -inotmatch $Pattern) {
                if ($count -ge $AttemptCount) {
                    throw "Expected value to match pattern: $($Pattern)`nBut found nothing`nOn: $($Browser.LocationURL)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }

        'value' {
            Write-MonocleHost -Message "Waiting for value: $Value"

            while ($Browser.Document.body.outerHTML -ine $Value) {
                if ($count -ge $AttemptCount) {
                    throw "Expected value: $($Value)`nBut found nothing`nOn: $($Browser.LocationURL)"
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

        [Parameter()]
        [int]
        $AttemptCount = 10
    )

    $count = 0
    $element = [System.DBNull]::Value

    Write-MonocleHost -Message "Waiting for element: $ElementName"

    while (Test-MonocleElementNull -Element $element) {
        if ($count -ge $AttemptCount) {
            throw "Expected element: $($ElementName)`nBut found nothing`nOn: $($Browser.LocationURL)"
        }

        $element = Get-MonocleElement `
            -FilterType $PSCmdlet.ParameterSetName `
            -Id $Id `
            -TagName $TagName `
            -AttributeName $AttributeName `
            -AttributeValue $AttributeValue `
            -ElementValue $ElementValue `
            -MPath $MPath `
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath
    )

    Write-MonocleHost -Message "Clicking element: $ElementName"

    $element = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    $element.click()

    Start-MonocleSleepWhileBusy
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

        [switch]
        $Uncheck
    )

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $ElementName"
    }
    else {
        Write-MonocleHost -Message "Checking element: $ElementName"
    }

    # Attempt to retrieve an appropriate element
    $element = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    # Attempt to toggle the check value
    $element.Checked = !$Uncheck

    Start-MonocleSleepWhileBusy
}