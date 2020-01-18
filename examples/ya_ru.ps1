$MODULE_NAME = 'src/Monocle.psm1'

$module_path = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path)
Import-Module -Name ('{0}/{1}' -f $module_path,$MODULE_NAME) -Force -ErrorAction Stop
# Create a browser object
$browser = New-MonocleBrowser -Type Chrome

# Monocle runs commands in web flows, for easy disposal and test tracking
# Each flow needs a name
Start-MonocleFlow -Name 'Load Ya.ru' -Browser $browser -ScriptBlock {

    # Tell the browser URL to navigate to
    Set-MonocleUrl -Url 'https://www.ya.ru'
    # Sleep while element is present. Default is to find element by id, with id of 'text' and wait indefinitely
Start-MonocleSleepUntilPresentElement -selector 'text' -kind 'id'
Start-MonocleSleepUntilPresentElement -selector 'button.button' -kind 'css' -delay 100
} -CloseBrowser -ScreenshotOnFail

# or close the browser manually:
#Close-MonocleBrowser -Browser $browser
