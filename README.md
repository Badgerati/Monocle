# Monocle

Monocle is a PowerShell Web Automation module, made to make automating and testing websites easier.

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

The following is a list of assertions available in Monocle:

* Assert-MonocleBodyValue
* Assert-MonocleElementValue

### MPath

MPath, or Monocle Path, is very similar to XPath and allows you to pin-point elements more easily.
You find elements initially by tag, and then optionally by zero-based index or attribute.

For example, take the following HTML:

```html
<html>
    <head>
        <title>Example</title>
    </head>
    <body>
        <form method='post' action='/example'>
            <input type='text' id='SomeInput' />
            <input type='text' data-type='test' />
            <input type='text' data-type='test' />
            <input type='submit' />
        </form>
    </body>
</html>
```

Here we have a very basic form with 3 textual inputs and a submit button.

Let's say we want to update the value of the first textual input, the one with an ID of `SomeInput`. The MPath to select this element would be:

```plain
form/input[@id=SomeInput]
```

In MPath, each query for an element is split by a slash (/). Each query starts with a tag name (form or input), followed optionally by square-brackets and a filter ([@id=SomeInput]).
Splitting down on the above MPath, Monocle will first find all `form` elements on the page. Then, it will find all input elements within those forms that have an `id` of `SomeInput`.

We can also simplify the above MPath to merely just:

```plain
input[@id=SomeInput]
```

Since Monocle only interacts with single elements, then once all queries have run the top first 1 element from the whole MPath is returned.

Let's now say we only want to update the value of the third textual input. Well, this one doesn't have an identifiers, so the MPath looks as follows:

```plain
form/input[2]
```

MPath is zero-based, so `input[2]` will select the third element in the form. Note, if you have two forms on your page, either use `form[0]` or `form[1]` else `input[2]` will literally return the third input in total.
If we just left the above as `form/input` then the input with ID of SomeInput will have been returned.

A more complex way of selecting the third input will be as follows:

```plain
form/input[@data-type=test][1]
```

Now, we will select the two inputs that have their `data-type` set to `test`, and then we will select the second of these inputs.

## FAQ

* I keep receiving the error:

   ```plain
   Creating an instance of the COM component with CLSID {0002DF01-0000-0000-C000-000000000046} from the IClassFactory 
   failed due to the following error: 800704a6 A system shutdown has already been scheduled. (Exception from HRESULT: 0x800704A6).
   ```

   Solution: Open IE, open setting the Compatability Viewing. Uncheck the two check boxes.
