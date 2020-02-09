$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Load Html' -Browser $browser -ScriptBlock {

    Set-MonocleUrl -Url 'https://html.com/input-type-checkbox/'

    $element = Get-MonocleElement -Id 'love'
    $element | Test-MonocleElementChecked
    $element | Invoke-MonocleElementCheck
    $element | Test-MonocleElementChecked

} -CloseBrowser