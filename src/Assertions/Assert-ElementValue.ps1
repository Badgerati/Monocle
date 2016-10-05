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

        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession
    
    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    $value = Get-ControlValue $control

    if ($value -ine $ExpectedValue)
    {
        $innerHtml = Get-ControlValue $control -useInnerHtml

        if ($innerHtml -ine $ExpectedValue)
        {
            throw ("Control's value is not valid.`nExpected: {0}`nBut got Value: {1}`nand InnerHTML: {2}" -f $ExpectedValue, $value, $innerHtml)
        }
    }
}