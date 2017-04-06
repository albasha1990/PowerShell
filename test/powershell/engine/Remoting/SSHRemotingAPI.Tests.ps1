Describe "SSH Remoting API Tests" -Tags "Feature" {

    Context "SSHConnectionInfo Class Tests" {

        It "SSHConnectionInfo constructor should throw null argument exception for null UserName parameter" {

            try
            {
                [System.Management.Automation.Runspaces.SSHConnectionInfo]::new(
                    [System.Management.Automation.Internal.AutomationNull]::Value,
                    "localhost",
                    [System.Management.Automation.Internal.AutomationNull]::Value,
                    0)

                throw "SSHConnectionInfo constructor did not throw expected PSArgumentNullException exception"
            }
            catch
            {
                $_.FullyQualifiedErrorId | Should Match "PSArgumentNullException"
            }
        }

        It "SSHConnectionInfo constructor should throw null argument exception for null HostName parameter" {

            try
            {
                [System.Management.Automation.Runspaces.SSHConnectionInfo]::new(
                    "UserName",
                    [System.Management.Automation.Internal.AutomationNull]::Value,
                    [System.Management.Automation.Internal.AutomationNull]::Value,
                    0)

                throw "SSHConnectionInfo constructor did not throw expected PSArgumentNullException exception"
            }
            catch
            {
                $_.FullyQualifiedErrorId | Should Match "PSArgumentNullException"
            }
        }

        It "SSHConnectionInfo should throw file not found exception for invalid key file path" {

            try
            {
                $sshConnectionInfo = [System.Management.Automation.Runspaces.SSHConnectionInfo]::new(
                    "UserName",
                    "localhost",
                    "NoValidKeyFilePath",
                    22)

                $rs = [runspacefactory]::CreateRunspace($sshConnectionInfo)
                $rs.Open()

                throw "SSHConnectionInfo did not throw expected FileNotFoundException exception"
            }
            catch
            {
                $expectedFileNotFoundExecption = $null
                if (($_.Exception -ne $null) -and ($_.Exception.InnerException -ne $null))
                {
                    $expectedFileNotFoundExecption = $_.Exception.InnerException.InnerException
                }

                ($expectedFileNotFoundExecption.GetType().FullName) | Should Be "System.IO.FileNotFoundException"
            }
        }

        It "SSHConnectionInfo should throw argument exception for invalid port (non 16bit uint)" {
            try 
            {
                
                $File = Get-ChildItem -File | select -First 1
                $sshConnectionInfo = [System.Management.Automation.Runspaces.SSHConnectionInfo]::new(
                    "UserName",
                    "localhost",
                    "ValidKeyFilePath",
                    99999)

                $rs = [runspacefactory]::CreateRunspace($sshConnectionInfo)
                $rs.Open()

                throw "SSHConnectionInfo did not throw expected ArgumentException exception"
            }
            catch
            {
                $expectedArgumentException = $_.Exception
                if (($_.Exception -ne $null) -and ($_.Exception.InnerException -ne $null))
                {
                    $expectedArgumentException = $_.Exception.InnerException
                }

                ($expectedArgumentException.GetType().FullName) | Should Be "System.ArgumentException"
            }
        }
    }
}
