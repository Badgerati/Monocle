$path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
Import-Module "$($path)/src/Monocle.psm1" -Force -ErrorAction Stop

# Monocle runs commands in web sessions, for easy disposal and test tracking
# Each session needs a name
InMonocleSession 'Load YouTube' {

    # Tell the session which URL to navigate to, will sleep while page is loading
    NavigateTo 'https://www.youtube.com'

    # Sets the search bar element to the passed value to query
    SetElementValue 'search_query' 'Beerus Madness (Extended)'

    # Tells the session to click the search button
    ClickElement 'search-btn'

    # Though all commands sleep when the page is busy, some buttons use javascript
    # to reform the page. The following will sleep the session until the passed URL is loaded.
    # If (default) 10 seconds passes and no URL, then the session fails
    ExpectUrl -StartsWith 'https://www.youtube.com/results?search_query='

    # Downloads an image from the page. This time it's using something called MPath (Monocle Path).
    # It's very similar to XPath, and allows you to pin-point elements more easily
    DownloadImage -MPath 'div[@data-context-item-id=SI6Yyr-iI6M]/img[0]' '.\beerus.jpg'

    # Tells the session to click the video in the results. The video link is found via MPath
    ClickElement -MPath 'a[@title=Dragon Ball Super Soundtrack - Beerus Madness (Extended)  - Duration: 10:00.]'

    # Again, we expect the URL to be loaded
    ExpectUrl 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

} -Visible -ScreenshotOnFail