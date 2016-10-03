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
        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    if ($Uncheck)
    {
        Write-MonocleHost "Unchecking element: $ElementName" $MonocleIESession
    }
    else
    {
        Write-MonocleHost "Checking element: $ElementName" $MonocleIESession
    }

    # Attempt to retrieve an appropriate control
    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
    
    # Attempt to toggle the check value
    $control.Checked = !$Uncheck
}