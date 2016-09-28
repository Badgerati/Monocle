# Monocle
Monocle is a PowerShell Web Automation module, made to make automating websites easier.

# Example
```PowerShell
$root = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path)
Import-Module "$root\Monocle.psm1" -DisableNameChecking -ErrorAction Stop

InMonocleSession 'Load YouTube' {
    NavigateTo 'https://www.youtube.com'
    SetElementValue 'search_query' 'Beerus Madness (Extended)'
    ClickElement 'search-btn'
    ExpectUrl 'https://www.youtube.com/results?search_query=' -StartsWith
    ClickElement 'Dragon Ball Super Soundtrack - Beerus Madness (Extended)' -TagName 'a' -AttributeName 'title'
    ExpectUrl 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'
} -Visible -ScreenshotOnFail -KeepOpen
```