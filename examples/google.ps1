$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Google Search' -Browser $browser -ScriptBlock {

    # navigate to google
    Set-MonocleUrl -Url 'https://www.google.com'

    # enter search value
    Get-MonocleElement -Id 'q' | Set-MonocleElementValue -Value 'PowerShell'

    # click search button
    Get-MonocleElement -TagName 'input' -AttributeName 'value' -AttributeValue 'Google Search' | Invoke-MonocleElementClick

    # wait for search page
    Wait-MonocleUrl -Url 'https://www.google.com/search' -StartsWith

    # click the google logo (back to home)
    Get-MonocleElement -Id 'logo' | Invoke-MonocleElementClick

    # ensure we're back home
    Wait-MonocleElement -Id 'q' | Out-Null

} -CloseBrowser