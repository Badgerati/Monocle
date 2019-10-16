function Get-Monocle2FAInterval
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [DateTime]
        $DateTime
    )

    # convert to utc
    $DateTime = $DateTime.ToUniversalTime()

    # get time interval for the date
    $secondsPerInterval = 30
    $epochTime = Get-Date "01/01/1970 00:00:00"
    $secondsSinceEpochTime = (New-TimeSpan -Start $epochTime -End $DateTime).TotalSeconds

    return [int64][math]::Floor($secondsSinceEpochTime / $secondsPerInterval)
}

function Get-Monocle2FAPin
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Secret,

        [Parameter(Mandatory=$true)]
        [long]
        $Interval
    )

    # convert the parameters to bytes
    $secretAsBytes = Convert-Monocle2FASecretToBytes -Secret $Secret
    $timeBytes = Convert-Monocle2FAIntervalToBytes -Interval $Interval

    # do the HMAC calculation with the default SHA1
    $hmacGen = [Security.Cryptography.HMACSHA1]::new($secretAsBytes)
    $hash = $hmacGen.ComputeHash($timeBytes)

    # take half the last byte
    $offset = ($hash[$hash.Length - 1] -band 0xF)

    # use it as an index into the hash bytes and take 4 bytes from there, big-endian needed
    $fourBytes = $hash[$offset..($offset + 3)]
    if ([BitConverter]::IsLittleEndian) {
        [array]::Reverse($fourBytes)
    }

    # remove the most significant bit
    $num = ([BitConverter]::ToInt32($fourBytes, 0) -band 0x7FFFFFFF)
    return ($num % 1000000).ToString().PadLeft(6, '0')
}

function Convert-Monocle2FASecretToBytes
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Secret
    )

    $Base32Charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

    # convert the secret from BASE32 to a byte array via a BigInteger so we can use its bit-shifting support
    $bigInteger = [Numerics.BigInteger]::Zero
    foreach ($char in ($secret.ToUpper() -replace '[^A-Z2-7]').GetEnumerator()) {
        $bigInteger = (($bigInteger -shl 5) -bor ($Base32Charset.IndexOf($char)))
    }

    [byte[]]$secretAsBytes = $bigInteger.ToByteArray()

    # BigInteger sometimes adds a 0 byte to the end, if it happens, we need to remove it
    if ($secretAsBytes[-1] -eq 0) {
        $secretAsBytes = $secretAsBytes[0..($secretAsBytes.Count - 2)]
    }

    # BigInteger stores bytes in Little-Endian order, but we need them in Big-Endian order.
    [array]::Reverse($secretAsBytes)
    return $secretAsBytes
}

function Convert-Monocle2FAIntervalToBytes
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [long]
        $Interval
    )

    $timeBytes = [BitConverter]::GetBytes($Interval)
    if ([BitConverter]::IsLittleEndian) {
        [array]::Reverse($timeBytes)
    }

    return $timeBytes
}