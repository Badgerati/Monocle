# Monocle
Monocle is a PowerShell Web Automation module, made to make automating websites easier.

# Install
To install the Monocle module globally, so you can `Import-Module Monocle`, then run the `install.ps1` script from an PowerShell console with admin priviledges.

# Example
```PowerShell
# if you didn't install globally, then import like so:
$root = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path)
Import-Module "$root\Monocle.psm1" -DisableNameChecking -ErrorAction Stop

# if you did import globally:
Import-Module Monocle

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
```

# FAQ
 * I keep receiving the error:
   
   ```
   Creating an instance of the COM component with CLSID {0002DF01-0000-0000-C000-000000000046} from the IClassFactory 
   failed due to the following error: 800704a6 A system shutdown has already been scheduled. (Exception from HRESULT: 0x800704A6).
   ```

   Solution: Open IE, open setting the Compatability Viewing. Uncheck the two check boxes.
