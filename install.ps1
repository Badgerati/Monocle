
# Determine which Program Files path to use
if (![string]::IsNullOrEmpty($env:ProgramFiles))
{
    $modulePath = Join-Path $env:ProgramFiles (Join-Path 'WindowsPowerShell' 'Modules')
}
else
{
    $modulePath = Join-Path ${env:ProgramFiles(x86)} (Join-Path 'WindowsPowerShell' 'Modules')
}

# Check to see if we need to create the Modules path
if (!(Test-Path $modulePath))
{
    Write-Host "Creating path: $modulePath"
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
    if (!$?)
    {
        throw "Failed to create: $modulePath"
    }
}

# Check to see if Modules path is in PSModulePaths
$psModules = $env:PSModulePath
if (!$psModules.Contains($modulePath))
{
    Write-Host 'Adding module path to PSModulePaths'
    $psModules += ";$modulePath"
    [Environment]::SetEnvironmentVariable('PSModulePath', $psModules)
    $env:PSModulePath = $psModules
}

# Create Monocle module
$monocleModulePath = Join-Path $modulePath 'Monocle'
if (!(Test-Path $monocleModulePath))
{
    Write-Host 'Creating Monocle module directory'
    New-Item -ItemType Directory -Path $monocleModulePath -Force | Out-Null
    if (!$?)
    {
        throw "Failed to create: $monocleModulePath"
    }
}

# Copy contents to module
Write-Host 'Copying Monocle content to module path'

New-Item -ItemType Directory -Path (Join-Path $monocleModulePath 'Functions') -Force | Out-Null
Copy-Item -Path ./src/Functions/* -Destination (Join-Path $monocleModulePath 'Functions') -Force | Out-Null

New-Item -ItemType Directory -Path (Join-Path $monocleModulePath 'Assertions') -Force | Out-Null
Copy-Item -Path ./src/Assertions/* -Destination (Join-Path $monocleModulePath 'Assertions') -Force | Out-Null

Copy-Item -Path ./src/Monocle.psm1 -Destination $monocleModulePath -Force | Out-Null
Copy-Item -Path ./src/Monocle.psd1 -Destination $monocleModulePath -Force | Out-Null
Copy-Item -Path ./LICENSE.txt -Destination $monocleModulePath -Force | Out-Null

Write-Host 'Monocle installed'