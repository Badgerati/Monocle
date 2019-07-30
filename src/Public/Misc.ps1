function SleepBrowser
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [int]
        $Seconds
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Sleeping for $Seconds second(s)" $MonocleIESession
    Start-Sleep -Seconds $Seconds
}

function Screenshot
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Path
    )

    # Attempt to retrieve this session
    Test-MonocleSession

    Invoke-Screenshot $MonocleIESession $Name $Path
    Start-SleepWhileBusy $MonocleIESession
}

function DownloadImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $ElementName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $OutFile,

        [Parameter()]
        [string]
        $TagName,

        [Parameter()]
        [string]
        $AttributeName,

        [switch]
        $FindByValue,

        [switch]
        $MPath
    )

    # attemp to retrieve this session
    Test-MonocleSession

    Write-MonocleHost "Downloading image from $ElementName" $MonocleIESession

    $control = Get-Control $MonocleIESession $ElementName -TagName $TagName -AttributeName $AttributeName -FindByValue:$FindByValue -MPath:$MPath

    $tag = $control.tagName
    if (($tag -ine 'img') -and ($tag -ine 'image')) {
        throw "Element $ElementName is not an image element: $tag"
    }

    if ([string]::IsNullOrWhiteSpace($control.src)) {
        throw "Element $ElementName has no src attribute"
    }

    Invoke-DownloadImage $MonocleIESession $control.src $OutFile
}