function Get-Monocle2FACode
{
    # with thanks to @Fraham
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Secret,

        [Parameter()]
        [DateTime]
        $DateTime
    )

    # set the date to now
    if ($null -eq $DateTime) {
        $DateTime = Get-Date
    }

    Write-MonocleHost -Message "Genetaring 2FA code for: $($DateTime.ToString('r'))"

    # get pin for the supplied date
    $interval = Get-Monocle2FAInterval -DateTime $DateTime

    # get pin for the time interval
    return (Get-Monocle2FAPin -Secret $Secret -Interval $interval)
}