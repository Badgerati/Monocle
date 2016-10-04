function SetElementValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $Value,

        [Parameter(Mandatory=$false)]
        [string] $TagName = $null,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName = $null,

        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    Write-MonocleHost "Setting element: $ElementName to value: '$Value'" $MonocleIESession

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    
    # Set the value of the control, if it's a select control, set the appropriate
    # option with value to be selected
    if ($control.Length -gt 1 -and $control[0].tagName -ieq 'option')
    {
        ($control | Where-Object { $_.innerHTML -ieq $Value }).Selected = $true
    }
    else
    {
        $control.value = $Value
    }
}