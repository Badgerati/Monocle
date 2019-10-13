$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
$path = "$($path)/src/Monocle.psm1"
Import-Module $path -Force -ErrorAction Stop

# Monocle runs commands in web flows, for easy disposal and test tracking
# Each flow needs a name
Start-MonocleFlow -Name 'Load YouTube' -Type 'Firefox' -ScriptBlock {

    # Tell the browser which URL to navigate to, will sleep while page is loading
    Set-MonocleUrl -Url 'https://www.youtube.com'

    # Sets the search bar element to the passed value to query
    Set-MonocleElementValue -Id 'search_query' -Value 'Beerus Madness (Extended)'

    # Tells the browser to click the search button
    Invoke-MonocleElementClick -Id 'search-icon-legacy'

    # Though all commands sleep when the page is busy, some buttons use javascript
    # to reform the page. The following will sleep the browser until the passed URL is loaded.
    # If (default) 10 seconds passes and no URL, then the flow fails
    Wait-MonocleUrl -Url 'https://www.youtube.com/results?search_query=' -StartsWith

    # Downloads an image from the page. This time it's using XPath
    Save-MonocleImage -XPath "//div[@data-context-item-id='SI6Yyr-iI6M']/img[1]" -Path '.\beerus.jpg'

    # Tells the browser to click the video in the results. The video link is found via XPath
    Invoke-MonocleElementClick -XPath "//a[@title='Dragon Ball Super Soundtrack - Beerus Madness (Extended)']"

    # Again, we expect the URL to be loaded
    Wait-MonocleUrl -Url 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

}