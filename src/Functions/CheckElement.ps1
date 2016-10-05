function CheckElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [switch] $Uncheck,
        [switch] $FindByValue,
        [switch] $MPath
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    if ($Uncheck)
    {
        Write-MonocleHost "Unchecking element: $ElementName" $MonocleIESession
    }
    else
    {
        Write-MonocleHost "Checking element: $ElementName" $MonocleIESession
    }

    # Attempt to retrieve an appropriate control
    $control = Get-Control $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue -mpath:$MPath
    
    # Attempt to toggle the check value
    $control.Checked = !$Uncheck
}