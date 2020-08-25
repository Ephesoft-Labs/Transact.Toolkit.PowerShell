# PSScriptAnalyzer - ignore irrelevant errors
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", '', Justification = "Fake credentials used for unit testing." )]
param ()

Import-Module '.\Ephesoft.Transact.BatchClass.psm1' -Force

Describe 'Batch Class CMDlets' {
  $Hostname = 'localhost'
  $SecStringFakePassword = ConvertTo-SecureString 'fakepass' -AsPlainText -Force
  $Cred = New-Object System.Management.Automation.PSCredential('fakeuser', $SecStringFakePassword)
  $ExpectedResult = 'BC1'
  $FilePath = 'TestDrive:\BatchClass.zip'
  $FilePathJPG = 'TestDrive:\BatchClass.jpg'
  $TempFileJPG = New-Item -ItemType File -Path $FilePathJPG -Value 'Test Content'

  # Global mocks
  Mock Invoke-RestMethod -ModuleName Ephesoft.Transact.BatchClass {
    return [pscustomobject]@{
      innerxml = '<data>fakedata</data>'
    }
  }

  Mock Select-XML -ModuleName 'Ephesoft.Transact.BatchClass' {
    $return = [pscustomobject] @{
      Node = 'BC1'
    }
    return $return
  }

  Context 'Get-TransactBatchClassList'{

    # Call CMDLet
    $Data = Get-TransactBatchClassList -Hostname $Hostname -Credential $Cred

    # Run tests
    It 'Returns correct data'{
      $Data | Should -Be $ExpectedResult
    }
  }

  Context 'Import-TransactBatchClass' {

    # Context specific mocks
    Mock Update-XMLTemplate -ModuleName 'Ephesoft.Transact.BatchClass' {}

    It 'Throws an error when the file cannot be found' {
      { Import-TransactBatchClass -Hostname $Hostname -FilePath $FilePath -Credential $Cred } | Should -Throw
    }

    It 'Throws an error when the filepath specified is not a .zip file' {
      { Import-TransactBatchClass -Hostname $Hostname -FilePath $TempFileJPG.FullName -Credential $Cred } | Should -Throw
    }
  }
}