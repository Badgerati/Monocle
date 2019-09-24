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
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    if ($Mask) {
        Write-MonocleHost -Message "Setting $($result.Id) element value to: ********"
    }
    else {
        Write-MonocleHost -Message "Setting $($result.Id) element value to: $Value"
    }

    # Set the value of the element, if it's a select element, set the appropriate option with value to be selected
    if ($result.Element.Length -gt 1 -and $result.Element[0].tagName -ieq 'option') {
        ($result.Element | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else {
        $result.Element.value = $Value
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

        [switch]
        $UseInnerHtml
    )

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath

    # get the value of the element, if it's a select element, get the appropriate option where option is selected
    if (($result.Element.Length -gt 1) -and ($result.Element[0].tagName -ieq 'option')) {
        return ($result.Element | Where-Object { $_.Selected -eq $true }).innerHTML
    }

    # if not a select element, then return either the innerHTML or value
    if ($UseInnerHtml) {
        return $result.Element.innerHTML
    }

    return $result.Element.value
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath
    )

    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath `
        -NoThrow

    return !(Test-MonocleElementNull -Element $result.Element)
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
    $result = Get-MonocleElement `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -MPath $MPath `
        -NoThrow

    Write-MonocleHost -Message "Waiting for element: $($result.Id)"

    while (Test-MonocleElementNull -Element $result.Element) {
        if ($count -ge $AttemptCount) {
            throw "Expected element: $($result.Id)`nBut found nothing`nOn: $($Browser.LocationURL)"
        }

        $result = Get-MonocleElement `
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
        $MPath,

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
        -MPath $MPath

    Write-MonocleHost -Message "Clicking element: $($result.Id)"

    $url = Get-MonocleUrl
    $result.Element.click() | Out-Null
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

        [Parameter(ParameterSetName='MPath')]
        [string]
        $MPath,

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
        -MPath $MPath

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $($result.Id)"
    }
    else {
        Write-MonocleHost -Message "Checking element: $($result.Id)"
    }

    # Attempt to toggle the check value
    $result.Element.Checked = !$Uncheck

    Start-MonocleSleepWhileBusy
}