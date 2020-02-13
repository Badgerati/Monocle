param(
    [Parameter(Mandatory=$true)]
    [string]
    $Url,

    [Parameter(Mandatory=$true)]
    [string]
    $Postcode,

    [Parameter(Mandatory=$true)]
    [string]
    $Address
)

$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Elements in iFrames' -Browser $browser -ScriptBlock {

    Set-MonocleUrl -Url $Url

    Get-MonocleElement -Id 'fillform-frame-1' | Enter-MonocleFrame -ScriptBlock {
        Get-MonocleElement -Id 'postcode_search' | Set-MonocleElementValue -Value $Postcode
        Get-MonocleElement -Id 'findAddressbtn' | Invoke-MonocleElementClick
        Get-MonocleElement -Id 'yourAddress' -WaitVisible | Set-MonocleElementValue -Value $Address
    }

} -CloseBrowser