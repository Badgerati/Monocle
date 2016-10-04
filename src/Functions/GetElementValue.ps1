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
        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    return Get-ControlValue $control -useInnerHtml:$UseInnerHtml
}