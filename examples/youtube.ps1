$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
Import-Module "$($path)/src/Monocle.psm1" -Force -ErrorAction Stop

# Monocle runs commands in web flows, for easy disposal and test tracking
# Each flow needs a name
Start-MonocleFlow -Name 'Load YouTube' -ScriptBlock {

    # Tell the browser which URL to navigate to, will sleep while page is loading
    Set-MonocleUrl -Url 'https://www.youtube.com'

    # Sets the search bar element to the passed value to query
    Set-MonocleElementValue -ElementName 'search_query' -Value 'Beerus Madness (Extended)'

    # Tells the browser to click the search button
    Invoke-MonocleElementClick -ElementName 'search-btn'

    # Though all commands sleep when the page is busy, some buttons use javascript
    # to reform the page. The following will sleep the browser until the passed URL is loaded.
    # If (default) 10 seconds passes and no URL, then the flow fails
    Wait-MonocleUrl -Url 'https://www.youtube.com/results?search_query=' -StartsWith

    # Downloads an image from the page. This time it's using something called MPath (Monocle Path).
    # It's very similar to XPath, and allows you to pin-point elements more easily
    Save-MonocleImage -MPath 'div[@data-context-item-id=SI6Yyr-iI6M]/img[0]' -Path '.\beerus.jpg'

    # Tells the browser to click the video in the results. The video link is found via MPath
    Invoke-MonocleElementClick -MPath -ElementName 'a[@title=Dragon Ball Super Soundtrack - Beerus Madness (Extended)  - Duration: 10:00.]'

    # Again, we expect the URL to be loaded
    Wait-MonocleUrl -Url 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

} -Visible -ScreenshotOnFail