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

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    Write-MonocleHost "Clicking element: $ElementName" $MonocleIESession

    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    $control.click()

    Start-SleepWhileBusy $MonocleIESession
}