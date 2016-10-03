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
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    return GetControlValue $control -useInnerHtml:$UseInnerHtml
}