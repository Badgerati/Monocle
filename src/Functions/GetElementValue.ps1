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