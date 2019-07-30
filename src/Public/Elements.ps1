function SetElementValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Value,

        [Parameter(Mandatory=$false)]
        [string] $TagName = $null,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName = $null,

        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Setting element: $ElementName to value: '$Value'" $MonocleIESession

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    
    # Set the value of the control, if it's a select control, set the appropriate
    # option with value to be selected
    if ($control.Length -gt 1 -and $control[0].tagName -ieq 'option')
    {
        ($control | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else
    {
        $control.value = $Value
    }
}

function GetElementValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [switch] $UseInnerHtml,
        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    return Get-ControlValue $control -useInnerHtml:$UseInnerHtml
}

function ExpectValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Value,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0
    
    Write-MonocleHost "Waiting for value: $Value" $MonocleIESession

    while ($MonocleIESession.Browser.Document.body.outerHTML -inotmatch $Value)
    {
        if ($count -ge $AttemptCount)
        {
            throw ("Expected value: $Value`nBut found nothing`nOn: {0}" -f $MonocleIESession.Browser.LocationURL)
        }
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected value loaded after $count second(s)" $MonocleIESession
}

function ExpectElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10,

        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    $count = 0
    $control = [System.DBNull]::Value

    Write-MonocleHost "Waiting for element: $ElementName" $MonocleIESession

    while (Test-ControlNull $control)
    {
        if ($count -ge $AttemptCount)
        {
            throw ("Expected element: $ElementName`nBut found nothing`nOn: {0}" -f $MonocleIESession.Browser.LocationURL)
        }

        $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath -noThrow
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected element loaded after $count second(s)" $MonocleIESession
}

function ClickElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Clicking element: $ElementName" $MonocleIESession

    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    $control.click()

    Start-SleepWhileBusy $MonocleIESession
}

function CheckElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [switch] $Uncheck,
        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    if ($Uncheck)
    {
        Write-MonocleHost "Unchecking element: $ElementName" $MonocleIESession
    }
    else
    {
        Write-MonocleHost "Checking element: $ElementName" $MonocleIESession
    }

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    
    # Attempt to toggle the check value
    $control.Checked = !$Uncheck
}