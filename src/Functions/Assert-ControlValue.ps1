function Assert-ControlValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ExpectedValue,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [switch] $UseInnerHtml
    )

    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
    
    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName
    $value = GetControlValue $control -useInnerHtml:$UseInnerHtml

    if ($value -ine $ExpectedValue)
    {
        throw ("Control's value is not valid.`nExpected: {0}`nBut got: {1}" -f $ExpectedValue, $value)
    }
}