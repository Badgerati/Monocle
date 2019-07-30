function SetElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
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
        $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Setting element: $ElementName to value: '$Value'" $MonocleIESession

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    # Set the value of the control, if it's a select control, set the appropriate
    # option with value to be selected
    if ($control.Length -gt 1 -and $control[0].tagName -ieq 'option') {
        ($control | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else {
        $control.value = $Value
    }
}

function GetElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
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

    # Attempt to retrieve this session
    Test-MonocleSession

    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    return Get-ControlValue $control -UseInnerHtml:$UseInnerHtml
}

function ExpectValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Value,

        [Parameter()]
        [int]
        $AttemptCount = 10
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0
    
    Write-MonocleHost "Waiting for value: $Value" $MonocleIESession

    while ($MonocleIESession.Browser.Document.body.outerHTML -inotmatch $Value)
    {
        if ($count -ge $AttemptCount) {
            throw "Expected value: $($Value)`nBut found nothing`nOn: $($MonocleIESession.Browser.LocationURL)"
        }
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected value loaded after $count second(s)" $MonocleIESession
}

function ExpectElement
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
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

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0
    $control = [System.DBNull]::Value

    Write-MonocleHost "Waiting for element: $ElementName" $MonocleIESession

    while (Test-ControlNull $control)
    {
        if ($count -ge $AttemptCount) {
            throw "Expected element: $($ElementName)`nBut found nothing`nOn: $($MonocleIESession.Browser.LocationURL)"
        }

        $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath -NoThrow
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected element loaded after $count second(s)" $MonocleIESession
}

function ClickElement
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
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

    # Attempt to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Clicking element: $ElementName" $MonocleIESession

    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    $control.click()

    Start-SleepWhileBusy $MonocleIESession
}

function CheckElement
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
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

    # Attempt to retrieve this session
    Test-MonocleSession

    if ($Uncheck) {
        Write-MonocleHost "Unchecking element: $ElementName" $MonocleIESession
    }
    else {
        Write-MonocleHost "Checking element: $ElementName" $MonocleIESession
    }

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath
    
    # Attempt to toggle the check value
    $control.Checked = !$Uncheck
}