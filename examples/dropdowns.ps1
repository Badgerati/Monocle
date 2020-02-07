$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Load W3C' -Browser $browser -ScriptBlock {

    Set-MonocleUrl -Url 'https://html.com/tags/select/'

    $element = Get-MonocleElement -Selector 'select'
    $element | Set-MonocleElementValue -Value 'Lesser flamingo'
    $element | Get-MonocleElementValue

} -CloseBrowser