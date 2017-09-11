. "$psscriptroot/TestRunner.ps1"
$AssemblyName = "System.Management.Automation"
# this list is taken from ${AssemblyName}.csproj
# excluded resources
$excludeList = "CoreMshSnapinResources.resx",
    "ErrorPackageRemoting.resx"
# run the tests
Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
