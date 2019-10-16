function Start-MonocleSleepWhileBusy
{
    [CmdletBinding()]
    param ()

    $count = 0
    $timeout = Get-MonocleTimeout

    while ((Invoke-MonocleJavaScript -Script 'return document.readyState') -ine 'complete')
    {
        if ($count -ge $timeout) {
            throw "Loading URL has timed-out after $timeout second(s)"
        }

        Start-Sleep -Seconds 1
        $count++
    }

    if ($count -gt 0) {
        Write-MonocleHost -Message "Browser busy for $count seconds(s)"
    }
}

function Invoke-MonocleDownloadImage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Source,

        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    Write-Verbose -Message "Downloading '$Source' to '$Path'"

    if ($PSVersionTable.PSVersion.Major -le 5) {
        Invoke-WebRequest -Uri $Source -OutFile $Path -UseBasicParsing | Out-Null
    }
    else {
        Invoke-WebRequest -Uri $Source -OutFile $Path | Out-Null
    }

    if (!$?) {
        throw 'Failed to download image'
    }
}

function Write-MonocleHost
{
    [CmdletBinding()]
    param (
        [Parameter()]
        $Message,

        [switch]
        $Backdent,

        [switch]
        $NoIndent
    )

    if ($NoIndent) {
        Write-Host -Object $Message
    }
    else {
        $Depth = [int]$env:MONOCLE_OUTPUT_DEPTH
        if ($Backdent) {
            $Depth--
        }

        Write-Host -Object "$('-' * $Depth)> $Message"
    }
}

function Test-MonocleUrl
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Url
    )

    # truncate the URL of any query parameters
    $Url = ([System.Uri]$Url).GetLeftPart([System.UriPartial]::Path)

    # initial code setting as success
    $code = 200
    $timeout = Get-MonocleTimeout
    $message = [string]::Empty

    $count = 1
    while ($count -le $timeout) {
        try {
            Write-MonocleHost -Message "Testing: $url [attempt: $($count)]"

            if ($PSVersionTable.PSVersion.Major -le 5) {
                $result = Invoke-WebRequest -Uri $Url -TimeoutSec $timeout -UseBasicParsing -ErrorAction Stop
            }
            else {
                $result = Invoke-WebRequest -Uri $Url -TimeoutSec $timeout -ErrorAction Stop
            }

            $code = [int]$result.StatusCode
            $message = $result.StatusDescription
        }
        catch [System.Net.WebException] {
            $ex = $_.Exception

            # if the exception doesn't contain a Response, then either the
            # host doesn't exist, there were SSL issues, or something else went wrong
            if ($null -eq $ex.Response) {
                $code = -1
                $message = $ex.Message
            }
            else {
                $code = [int]$ex.Response.StatusCode.Value__
                $message = $ex.Response.StatusDescription
            }
        }
        catch {
            $code = -1
            $message = $_.Exception.Message
        }

        if (($code -eq -1) -or ($code -ge 400)) {
            $count++
            if ($count -gt $timeout) {
                break
            }

            Start-Sleep -Seconds 1
        }
        else {
            break
        }
    }

    # anything that is 1xx-2xx is normally successful, anything that's
    # 400+ is normally always a failure to load
    # -1 is a fatal error (SSL, invalid host, etc)
    if (($code -eq -1) -or ($code -ge 400)) {
        throw "Failed to load URL: '$Url'`nStatus: $code`nMessage: $message"
    }

    return $code
}