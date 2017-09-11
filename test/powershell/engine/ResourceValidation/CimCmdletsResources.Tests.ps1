. "$psscriptroot/TestRunner.ps1"

$assemblyName = "Microsoft.Management.Infrastructure.CimCmdlets"
# this list is taken from ${AssemblyName}.csproj
# excluded resources
$excludeList = @()
# load the module since it isn't there by default
import-module CimCmdlets

# run the tests
Test-ResourceStrings -AssemblyName $AssemblyName -ExcludeList $excludeList
