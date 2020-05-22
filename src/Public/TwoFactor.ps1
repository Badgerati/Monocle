<#
.SYNOPSIS
Generate a 2FA code.

.DESCRIPTION
Generate a 2FA code.

.PARAMETER Secret
The secret to use when generating the 2FA code.

.PARAMETER DateTime
The DateTime to generate the code for, leave empty for the current time.

.EXAMPLE
$code = Get-Monocle2FACode -Secret 50M3F4K3C0D3

.EXAMPLE
$code = Get-Monocle2FACode -Secret 50M3F4K3C0D3 -DateTime [datetime]::Now.AddSeconds(5)
#>
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