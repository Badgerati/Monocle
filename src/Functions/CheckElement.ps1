function CheckElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [switch] $Uncheck
    )

    # Attempt to retrieve this sessions Monocle
    if ((Get-Variable -Name MonocleIESession -ValueOnly -ErrorAction Stop) -eq $null)
    {
        throw 'No Monocle session for IE found.'
    }

    # Attempt to retrieve an appropriate control
    $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName
    
    try
    {
        # Attempt to toggle the check value
        $control.Checked = !$Uncheck
    }
    catch [exception]
    {
        Write-Error "Failed to toggle check of '$ElementName' control"
        throw
    }
}