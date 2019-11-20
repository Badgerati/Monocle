Task 'Build' Selenium, { }

Task 'Selenium' {
    if (Test-Path ./src/lib) {
        Remove-Item -Path ./src/lib -Force -Recurse -ErrorAction Stop | Out-Null
    }

    if (Test-Path ./temp) {
        Remove-Item -Path ./temp -Force -Recurse -ErrorAction Stop | Out-Null
    }

    $packages = @{
        'Selenium.WebDriver' = '3.141.0'
        'Selenium.Support' = '3.141.0'
        'Selenium.WebDriver.ChromeDriver' = '78.0.3904.10500'
        'Selenium.WebDriver.IEDriver' = '3.150.1'
        'Selenium.WebDriver.GeckoDriver' = '0.26.0'
    }

    $packages.Keys | ForEach-Object {
        nuget install $_ -source nuget.org -version $packages[$_] -outputdirectory ./temp | Out-Null
    }

    # web drivers
    New-Item -Path ./src/lib/WebDriver -ItemType Directory -Force | Out-Null

    Copy-Item -Path "./temp/Selenium.WebDriver.$($packages['Selenium.WebDriver'])/lib/*" -Destination ./src/lib/WebDriver -Recurse -Force | Out-Null
    Copy-Item -Path "./temp/Selenium.Support.$($packages['Selenium.Support'])/lib/*" -Destination ./src/lib/WebDriver -Recurse -Force | Out-Null

    Remove-Item -Path ./src/lib/WebDriver/net20 -Force -Recurse -ErrorAction Ignore | Out-Null
    Remove-Item -Path ./src/lib/WebDriver/net35 -Force -Recurse -ErrorAction Ignore | Out-Null
    Remove-Item -Path ./src/lib/WebDriver/net40 -Force -Recurse -ErrorAction Ignore | Out-Null

    # browsers
    New-Item -Path ./src/lib/Browsers -ItemType Directory -Force | Out-Null
    New-Item -Path ./src/lib/Browsers/win -ItemType Directory -Force | Out-Null
    New-Item -Path ./src/lib/Browsers/linux -ItemType Directory -Force | Out-Null
    New-Item -Path ./src/lib/Browsers/mac -ItemType Directory -Force | Out-Null

    # win
    "./temp/Selenium.WebDriver.IEDriver.$($packages['Selenium.WebDriver.IEDriver'])/driver/*" | Out-Default
    Copy-Item -Path "./temp/Selenium.WebDriver.IEDriver.$($packages['Selenium.WebDriver.IEDriver'])/driver/*" -Destination ./src/lib/Browsers/win/ -Recurse -Force | Out-Null
    Copy-Item -Path "./temp/Selenium.WebDriver.GeckoDriver.$($packages['Selenium.WebDriver.GeckoDriver'])/driver/win64/*" -Destination ./src/lib/Browsers/win/ -Recurse -Force | Out-Null
    Copy-Item -Path "./temp/Selenium.WebDriver.ChromeDriver.$($packages['Selenium.WebDriver.ChromeDriver'])/driver/win32/*" -Destination ./src/lib/Browsers/win/ -Recurse -Force | Out-Null

    # linux
    Copy-Item -Path "./temp/Selenium.WebDriver.GeckoDriver.$($packages['Selenium.WebDriver.GeckoDriver'])/driver/linux64/*" -Destination ./src/lib/Browsers/linux/ -Recurse -Force | Out-Null
    Copy-Item -Path "./temp/Selenium.WebDriver.ChromeDriver.$($packages['Selenium.WebDriver.ChromeDriver'])/driver/linux64/*" -Destination ./src/lib/Browsers/linux/ -Recurse -Force | Out-Null

    # mac
    Copy-Item -Path "./temp/Selenium.WebDriver.GeckoDriver.$($packages['Selenium.WebDriver.GeckoDriver'])/driver/mac64/*" -Destination ./src/lib/Browsers/mac/ -Recurse -Force | Out-Null
    Copy-Item -Path "./temp/Selenium.WebDriver.ChromeDriver.$($packages['Selenium.WebDriver.ChromeDriver'])/driver/mac64/*" -Destination ./src/lib/Browsers/mac/ -Recurse -Force | Out-Null

    # clean up temp
    if (Test-Path ./temp) {
        Remove-Item -Path ./temp -Force -Recurse | Out-Null
    }
}