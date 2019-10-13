Task 'Build' Selenium, { }

Task 'Selenium' {
    #if (Test-Path ./src/lib) {
    #    Remove-Item -Path ./src/lib -Force -Recurse -ErrorAction Stop | Out-Null
    #}

    if (Test-Path ./temp) {
        Remove-Item -Path ./temp -Force -Recurse -ErrorAction Stop | Out-Null
    }

    $packages = @{
        'Selenium.WebDriver' = '3.141.0'
        'Selenium.Support' = '3.141.0'
        'Selenium.WebDriver.ChromeDriver' = '77.0.3865.4000'
        'Selenium.WebDriver.IEDriver' = '3.150.0'
        'Selenium.WebDriver.GeckoDriver' = '0.26.0'
    }

    $packages.Keys | ForEach-Object {
        nuget install $_ -source nuget.org -version $packages[$_] -outputdirectory ./temp | Out-Null
    }

    #New-Item -Path ./src/lib/YamlDotNet -ItemType Directory -Force | Out-Null
    #Copy-Item -Path "./temp/YamlDotNet.$($version)/lib/*" -Destination ./src/lib/YamlDotNet -Recurse -Force | Out-Null

    #if (Test-Path ./temp) {
    #    Remove-Item -Path ./temp -Force -Recurse | Out-Null
    #}

    #Remove-Item -Path ./src/lib/YamlDotNet/net20 -Force -Recurse | Out-Null
    #Remove-Item -Path ./src/lib/YamlDotNet/net35 -Force -Recurse | Out-Null
    #Remove-Item -Path ./src/lib/YamlDotNet/net35-client -Force -Recurse | Out-Null
}