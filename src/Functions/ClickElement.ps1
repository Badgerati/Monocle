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

        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    Write-MonocleHost "Clicking element: $ElementName" $MonocleIESession

    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    $control.click()

    SleepWhileBusy $MonocleIESession
}