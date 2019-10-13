# Monocle

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Monocle/master/LICENSE.txt)
[![PowerShell](https://img.shields.io/powershellgallery/dt/monocle.svg?label=PowerShell&colorB=085298)](https://www.powershellgallery.com/packages/Monocle)

Monocle is a Cross-Platform PowerShell Web Automation module, made to make automating and testing websites easier.

Monocle currently supports the following browsers:

* IE
* Google Chrome
* Firefox

## Install

```powershell
Install-Module -Name Monocle
Import-Module -Name Monocle
```

## Example

```powershell
# if you didn't install globally, then import like so:
$root = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path)
Import-Module "$root\Monocle.psm1" -DisableNameChecking -ErrorAction Stop

# if you did import globally:
Import-Module Monocle

# Monocle runs commands in web flows, for easy disposal and test tracking
# Each browser needs a name
Start-MonocleFlow -Name 'Load YouTube' -Type 'Chrome' -ScriptBlock {

    # Tell the browser which URL to navigate to, will sleep while page is loading
    Set-MonocleUrl -Url 'https://www.youtube.com'

    # Sets the search bar element to the passed value to query
    Set-MonocleElementValue -Id 'search_query' -Value 'Beerus Madness (Extended)'

    # Tells the browser to click the search button
    Invoke-MonocleElementClick -Id 'search-btn'

    # Though all commands sleep when the page is busy, some buttons use javascript
    # to reform the page. The following will sleep the browser until the passed URL is loaded.
    # If (default) 10 seconds passes and no URL, then the flow fails
    Wait-MonocleUrl -Url 'https://www.youtube.com/results?search_query=' -StartsWith

    # Downloads an image from the page. This time it's using something called MPath (Monocle Path).
    # It's very similar to XPath, and allows you to pin-point elements more easily
    Save-MonocleImage -XPath "//div[@data-context-item-id='SI6Yyr-iI6M']/img[1]" -Path '.\beerus.jpg'

    # Tells the browser to click the video in the results. The video link is found via MPath
    Invoke-MonocleElementClick -MPath "//a[@title='Dragon Ball Super Soundtrack - Beerus Madness (Extended)']"

    # Again, we expect the URL to be loaded
    Wait-MonocleUrl -Url 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

}
```

## Documentation

### Functions

The following is a list of available functions in Monocle. These can be used, after calling `Import-Module -Name Monocle`.

* Invoke-MonocleElementCheck
* Invoke-MonocleElementClick
* Save-MonocleImage
* Wait-MonocleElement
* Wait-MonocleUrl
* Wait-MonocleValue
* Get-MonocleElementValue
* Start-MonocleFlow
* Edit-MonocleUrl
* Set-MonocleUrl
* Invoke-MonocoleScreenshot
* Set-MonocleElementValue
* Start-MonocleSleep
* Restart-MonocleBrowser
* Get-MonocleUrl
* Test-MonocleElement

The following is a list of assertions available in Monocle:

* Assert-MonocleBodyValue
* Assert-MonocleElementValue

## FAQ

* I keep receiving the error:

   ```plain
   Creating an instance of the COM component with CLSID {0002DF01-0000-0000-C000-000000000046} from the IClassFactory 
   failed due to the following error: 800704a6 A system shutdown has already been scheduled. (Exception from HRESULT: 0x800704A6).
   ```

   Solution: Open IE, open setting the Compatability Viewing. Uncheck the two check boxes.
