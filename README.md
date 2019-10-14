# Monocle

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Monocle/master/LICENSE.txt)
[![PowerShell](https://img.shields.io/powershellgallery/dt/monocle.svg?label=PowerShell&colorB=085298)](https://www.powershellgallery.com/packages/Monocle)

Monocle is a Cross-Platform PowerShell Web Automation module, made to make automating and testing websites easier. It's a PowerShell wrapper around Selenium, with the aim of abstracting Selenium away from the user.

Monocle currently supports the following browsers:

* IE
* Google Chrome
* Firefox

## Install

```powershell
Install-Module -Name Monocle
```

## Example

```powershell
Import-Module Monocle

# create a browser
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
Start-MonocleFlow -Name 'Load YouTube' -Browser $browser -ScriptBlock {

    # tell the browser which URL to navigate to, will wait for the page to load
    Set-MonocleUrl -Url 'https://www.youtube.com'

    # sets the element's value, selecting the element by ID/Name
    Set-MonocleElementValue -Id 'search_query' -Value 'Beerus Madness (Extended)'

    # click the search button
    Invoke-MonocleElementClick -Id 'search-btn'

    # wait for the URL to change to start with the following value
    Wait-MonocleUrl -Url 'https://www.youtube.com/results?search_query=' -StartsWith

    # downloads an image from the page, selcted by using an XPath to an element
    Save-MonocleImage -XPath "//div[@data-context-item-id='SI6Yyr-iI6M']/img[1]" -Path '.\beerus.jpg'

    # tells the browser to click the video in the results
    Invoke-MonocleElementClick -XPath "//a[@title='Dragon Ball Super Soundtrack - Beerus Madness (Extended)']"

    # wait for the URL to be loaded
    Wait-MonocleUrl -Url 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'

}

# dispose the browser
Close-MonocleBrowser -Browser $browser
```

## Documentation

### Functions

The following is a list of available functions in Monocle:

* Assert-MonocleBodyValue
* Assert-MonocleElementValue
* Close-MonocleBrowser
* Edit-MonocleUrl
* Get-MonocleElementValue
* Get-MonocleHtml
* Get-MonocleUrl
* Invoke-MonocleElementCheck
* Invoke-MonocleElementClick
* Invoke-MonocleRetryScript
* Invoke-MonocoleScreenshot
* New-MonocleBrowser
* Restart-MonocleBrowser
* Save-MonocleImage
* Set-MonocleElementValue
* Set-MonocleUrl
* Start-MonocleFlow
* Start-MonocleSleep
* Test-MonocleElement
* Wait-MonocleElement
* Wait-MonocleUrl
* Wait-MonocleUrlDifferent
* Wait-MonocleValue

### Screenshots

There are two main ways to take a screenshot of the browser. The first it to tell Monocle to automatically take a screenshot whenever a flow fails. You can do this by using the `-ScreenshotPath` and `-ScreenshotOnFail` parameters on the `Start-MonocleFlow` function:

```powershell
Start-MonocleFlow -Name '<name>' -Browser $browser -ScriptBlock {
    # failing logic
} -ScreenshotPath './path' -ScreenshotOnFail
```

Or, you can take a screenshot directly:

```powershell
Invoke-MonocoleScreenshot -Name 'screenshot.png' -Path './path'
```

> Not supplying `-ScreenshotPath` or `-Path` will default to the current path.

### Waiting

There are inbuilt function to wait for a URL or element. However, to wait for an element during a Set/Click call you can use the `-Wait` switch:

```powershell
Invoke-MonocleElementClick -Id 'element-id' -Wait
```

### Docker