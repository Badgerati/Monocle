function Set-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [Parameter()]
        [string]
        $TagName = $null,

        [Parameter()]
        [string]
        $AttributeName = $null,

        [switch]
        $FindByValue,

        [switch]
        $MPath,

        [switch]
        $Mask
    )

    if ($Mask) {
        Write-MonocleHost -Message "Setting element: $ElementName to value: '********'"
    }
    else {
        Write-MonocleHost -Message "Setting element: $ElementName to value: '$Value'"
    }

    # Attempt to retrieve an appropriate element
    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    # Set the value of the element, if it's a select element, set the appropriate
    # option with value to be selected
    if ($element.Length -gt 1 -and $element[0].tagName -ieq 'option') {
        ($element | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else {
        $element.value = $Value
    }
}

function Get-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [switch]
        $UseInnerHtml,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    # get the value of the element, if it's a select element, get the appropriate option where option is selected
    if (($element.Length -gt 1) -and ($element[0].tagName -ieq 'option'))
    {
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [Parameter()]
        [int]
        $AttemptCount = 10,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    $count = 0
    $element = [System.DBNull]::Value

    Write-MonocleHost -Message "Waiting for element: $ElementName"

    while (Test-MonocleElementNull -Element $element) {
        if ($count -ge $AttemptCount) {
            throw "Expected element: $($ElementName)`nBut found nothing`nOn: $($Browser.LocationURL)"
        }

        $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath -NoThrow
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost -Message "Expected element loaded after $count second(s)"
}

function Invoke-MonocleElementClick
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    Write-MonocleHost -Message "Clicking element: $ElementName"

    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    $element.click()

    Start-MonocleSleepWhileBusy
}

function Invoke-MonocleElementCheck
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $ElementName,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [switch]
        $Uncheck,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $ElementName"
    }
    else {
        Write-MonocleHost -Message "Checking element: $ElementName"
    }

    # Attempt to retrieve an appropriate element
    $element = Get-MonocleElement -Name $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    # Attempt to toggle the check value
    $element.Checked = !$Uncheck

    Start-MonocleSleepWhileBusy
}