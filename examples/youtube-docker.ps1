Import-Module -Name Monocle -Force -ErrorAction Stop

# Create a browser object
#Install-MonocleDriver -Type Chrome -Version '79.0.3945.3600'
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
# Each flow needs a name
Start-MonocleFlow -Name 'Load YouTube' -Browser $browser -ScriptBlock {

    # Tell the browser which URL to navigate to, will sleep while page is loading
    Set-MonocleUrl -Url 'https://www.youtube.com'

    # Sets the search bar element to the passed value to query
    Get-MonocleElement -Selector 'input[name=search_query]' | Set-MonocleElementValue -Value 'Beerus Madness (Extended)'
    #Get-MonocleElement -Id 'search_query' | Set-MonocleElementValue -Value 'Beerus Madness (Extended)'

    # Tells the browser to click the search button
    Wait-MonocleElement -Id 'search-icon-legacy' | Out-Null
    Get-MonocleElement -Id 'search-icon-legacy' | Invoke-MonocleElementClick

    # Though all commands sleep when the page is busy, some buttons use javascript
    # to reform the page. The following will sleep the browser until the passed URL is loaded.
    # If (default) 10 seconds passes and no URL, then the flow fails
    Wait-MonocleUrl -Url 'https://www.youtube.com/results?search_query=' -StartsWith

    # Downloads an image from the page. This time it's using XPath
    #Get-MonocleElement -XPath "//div[@data-context-item-id='SI6Yyr-iI6M']/img[1]" | Save-MonocleImage -FilePath '.\beerus.jpg'

    # Tells the browser to click the video in the results. The video link is found via XPath
    Get-MonocleElement -XPath "//a[@title='Dragon Ball Super Soundtrack - Beerus Madness (Extended)']" | Invoke-MonocleElementClick

    # Again, we expect the URL to be loaded
    Wait-MonocleUrl -Url 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

} -CloseBrowser -ScreenshotOnFail

# or close the browser manually if not using default:
#Close-MonocleBrowser -Browser $browser