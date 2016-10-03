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

    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    $control.click()

    SleepWhileBusy $MonocleIESession
}