$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Scrolling' -Browser $browser -ScriptBlock {

    # navigate to google
    Set-MonocleUrl -Url 'https://en.wikipedia.org/wiki/PowerShell' -Force

    # move to the middle of the page
    Move-MonoclePage -To Middle
    Start-MonocleSleep -Seconds 2

    # move to a specific position
    Move-MonoclePage -Position 2000
    Start-MonocleSleep -Seconds 2

    # move to the top of the page
    Move-MonoclePage -To Top
    Start-MonocleSleep -Seconds 2

    # move to the footer - by element
    Get-MonocleElement -Id 'footer' | Move-MonoclePage
    Start-MonocleSleep -Seconds 2

} -CloseBrowser