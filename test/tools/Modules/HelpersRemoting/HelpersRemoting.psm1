#
# This module include help functions for writing remoting tests
#

$Script:AppVeyorRemoteCred = $null

if ($IsWindows) {
    try { $Script:AppVeyorRemoteCred = Import-Clixml -Path "$env:TEMP\AppVeyorRemoteCred.xml" } catch { }
}


function New-RemoteRunspace
{
    $wsmanConInfo = [System.Management.Automation.Runspaces.WSManConnectionInfo]::new()

    if ($Script:AppVeyorRemoteCred)
    {
        Write-Verbose "Using Global AppVeyor Credential" -Verbose
        $wsmanConInfo.Credential = $Script:AppVeyorRemoteCred
    }
    else
    {
        Write-Verbose "Using Implicit Credential" -Verbose
    }

    $remoteRunspace = [runspacefactory]::CreateRunspace($Host, $wsmanConInfo)
    $remoteRunspace.Open()

    return $remoteRunspace
}

function CreateParameters
{
    param (
        [string] $ComputerName
        [string] $Name,
        [string] $ConfigurationName,
        [System.Management.Automation.Remoting.PSSessionOption] $SessionOption)

    if($ComputerName) {
        $parameters = @{ ComputerName = $ComputerName; }
    }
    else {
        $parameters = @{ ComputerName = "."; }
    }

    if ($Name) {
        $parameters["Name"] = $Name
    }

    if ($ConfigurationName) {
        $parameters["ConfigurationName"] = $ConfigurationName
    }

    if ($SessionOption) {
        $parameters["SessionOption"] = $SessionOption
    }

    if ($Script:AppVeyorRemoteCred)
    {
        Write-Verbose "Using Global AppVeyor Credential" -Verbose
        $parameters["Credential"] = $Script:AppVeyorRemoteCred
    }
    else
    {
        Write-Verbose "Using Implicit Credential" -Verbose
    }

    return $parameters
}
function New-RemoteSession
{
    param (
        [string] $Name,
        [string] $ConfigurationName,
        [switch] $CimSession,
        [System.Management.Automation.Remoting.PSSessionOption] $SessionOption)

    $parameters = CreateParameters -Name $Name -ConfigurationName $ConfigurationName -SessionOption $SessionOption

    if ($CimSession) {
        $session = New-CimSession @parameters
    } else {
        $session = New-PSSession @parameters
    }

    return $session
}

function Invoke-RemoteCommand
{
    param (
        [string] $ComputerName,
        [scriptblock] $ScriptBlock,
        [string] $ConfigurationName,
        [switch] $InDisconnectedSession)

    $parameters = CreateParameters -ComputerName $ComputerName -ConfigurationName $ConfigurationName
    $parameters.Add('ScriptBlock', $ScriptBlock)
    $parameters.Add('InDisconnectedSession', $InDisconnectedSession.IsPresent)

    Invoke-Command @parameters
}

function Enter-RemoteSession
{
    param(
        [string] $Name,
        [string] $ConfigurationName,
        [System.Management.Automation.Remoting.PSSessionOption] $SessionOption)

    $parameters = CreateParameters -Name $Name -ConfigurationName $ConfigurationName -SessionOption $SessionOption
    Enter-PSSession @parameters
}
