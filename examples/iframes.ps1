param(
    [Parameter(Mandatory=$true)]
    [string]
    $Url
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
        Get-MonocleElement -Id 'postcode_search' | Set-MonocleElementValue -Value 'NN1 1AA'
        Get-MonocleElement -Id 'findAddressbtn' | Invoke-MonocleElementClick
    }

    Start-Sleep -Seconds 5

} -CloseBrowser