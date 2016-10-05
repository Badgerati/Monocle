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
    ExpectUrl -StartsWith 'https://www.youtube.com/results?search_query='
    DownloadImage -MPath 'div[@data-context-item-id=SI6Yyr-iI6M]/img[0]' '.\beerus.jpg'
    ClickElement -MPath 'a[@title=Dragon Ball Super Soundtrack - Beerus Madness (Extended)  - Duration: 10:00.]'
    ExpectUrl 'https://www.youtube.com/watch?v=SI6Yyr-iI6M'
} -Visible -ScreenshotOnFail
```