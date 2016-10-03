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

    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    return GetControlValue $control -useInnerHtml:$UseInnerHtml
}