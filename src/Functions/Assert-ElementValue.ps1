function Assert-ElementValue
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

        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }
    
    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    $value = GetControlValue $control

    if ($value -ine $ExpectedValue)
    {
        $innerHtml = GetControlValue $control -useInnerHtml

        if ($innerHtml -ine $ExpectedValue)
        {
            throw ("Control's value is not valid.`nExpected: {0}`nBut got Value: {1}`nand InnerHTML: {2}" -f $ExpectedValue, $value, $innerHtml)
        }
    }
}