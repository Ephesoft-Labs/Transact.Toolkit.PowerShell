# The test cases in this file are loaded into the common Rest Call tests in Ephesoft.Transact.RestCall.Tests.ps1
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", '', Justification = "Fake credentials used for unit testing." )]
param ()

# Set static variables
$Hostname = 'localhost'
$SecStringFakePassword = ConvertTo-SecureString 'fakepass' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('fakeuser', $SecStringFakePassword)
$FilePath = 'C:\Fake\BatchClass.zip'
$BatchClassName = 'MyBatchClass'
$BatchName = 'MyBatch'
$FilePath = 'C:\Fake\MyBatch.zip'
$BatchClassID = 'BC10'

# Configure test cases.  Each test case is run against base tests as well as tests specific for the REST method used.
$TestCases = @(
  [pscustomobject] @{
    CMDLet = 'Get-TransactBatchClassList'
    ModuleName = 'Ephesoft.Transact.BatchClass'
    Method = 'Get'
    ExpectedURL = "^https:\/\/localhost\/dcma\/rest\/getBatchClassList"
    Params = @{
      Hostname = $Hostname
      Credential = $Cred
    }
  },
  [pscustomobject] @{
    CMDLet = 'Import-TransactBatchClass'
    ModuleName = 'Ephesoft.Transact.BatchClass'
    Method = 'Post'
    ExpectedURL = "^https:\/\/localhost\/dcma\/rest\/importBatchClass"
    Params = @{
      Hostname = $Hostname
      Credential = $Cred
      FilePath = $FilePath
    }
  },
  [pscustomobject] @{
    CMDLet = 'Submit-TransactBatch'
    ModuleName = 'Ephesoft.Transact.Batch'
    Method = 'Post'
    ExpectedURL = "^https:\/\/localhost\/dcma\/rest\/uploadBatch\/$BatchClassId\/$BatchName"
    Params = @{
      Hostname = $Hostname
      Credential = $Cred
      FilePath = $FilePath
      BatchClassName = $BatchClassName
    }
  }
)

return $TestCases