function ExpectElement
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $ElementName,

        [Parameter(Mandatory=$false)]
        [string] $TagName,

        [Parameter(Mandatory=$false)]
        [string] $AttributeName,

        [Parameter(Mandatory=$false)]
        [int] $AttemptCount = 10,

        [switch] $FindByValue
    )

    # Attempt to retrieve this sessions Monocle
    Test-MonocleSession

    $count = 0
    $control = [System.DBNull]::Value

    Write-MonocleHost "Waiting for element: $ElementName" $MonocleIESession

    while (IsControlNull $control)
    {
        if ($count -ge $AttemptCount)
        {
            throw ("Expected element: $ElementName`nBut found nothing`nOn: {0}" -f $MonocleIESession.Browser.LocationURL)
        }

        $control = GetControl $MonocleIESession $ElementName -tagName $TagName -attributeName $AttributeName -findByValue:$FindByValue
        
        $count++
        Start-Sleep -Seconds 1
    }

    Write-MonocleHost "Expected element loaded after $count second(s)" $MonocleIESession
}