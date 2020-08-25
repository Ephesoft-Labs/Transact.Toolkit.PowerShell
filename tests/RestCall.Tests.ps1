Import-Module '.\Ephesoft.Transact.BatchClass.psm1' -Force
Import-Module '.\Ephesoft.Transact.Batch.psm1' -Force

# This file tests CMDLets that wrap REST API calls with standard tests.
# WHAT THESE TESTS COVER
#  * The correct REST method is called
#  * The content type is set correctly
#  * The URI is correctly formed
#  * A body is only passed when using a Post method
#  * When a body is passed, it contains the expected attributes
#
# ADDING TESTS
#  To add a CMDLet to test, create a new pscustom object in the TestCases array in RestCall.TestsCases.ps1.
#  Make sure to include the Module name, Method, and any Params that should be passed when the CMDLet is run.
#
# OTHER TESTS
#  All tests for additional coverage should be placed in the test file associated with the CMDLet's module.
Describe 'REST API wrapper CMDLets' {

  # Get list of test cases
  $TestCases = & ".\tests\RestCall.TestCases.ps1"

  # Global mocks
  # Mock Invoke-RestMethod for
  $ModulesToMock = $TestCases.ModuleName | Select-Object -Unique
  foreach ($ModuleName in $ModulesToMock) {
    Mock Invoke-RestMethod -ModuleName $ModuleName {
      return [pscustomobject]@{
        innerxml = @{
          Identifier = 'BC10'
          Name = 'MyBatchClass'
        }
      }
    }

    Mock Select-XML -ModuleName $ModuleName {
      $return = [pscustomobject] @{
        Node =  @{
          Identifier = 'BC10'
          Name = 'MyBatchClass'
        }
      }
      return $return
    }

    Mock Get-Content -ModuleName $ModuleName {}
    Mock Update-XMLTemplate -ModuleName $ModuleName {}
    Mock Test-Path -ModuleName $ModuleName {$true}
    Mock Get-MultiPartFileContent -ModuleName $ModuleName {@{Content = 'FakeContent'}}
    Mock Get-ChildItem -ModuleName $ModuleName {@{Name = 'MyBatch.zip'}}
  }

  # Function to test base requirements on all test cases
  Function Test-BaseRestRequirement {
    It 'Is using the correct content type' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $ContentType -eq 'application/xml'
      }
    }
    It 'Has a valid URI' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $URI -match $TestCase.ExpectedURL
      }
    }
    # Every call must have auth in headers
    It 'Has required auth data in headers' {
      $Base64Creds = [System.Convert]::TOBase64String([System.Text.Encoding]::UTF8.GetBytes("$($TestCase.Params.Credential.Username):$($TestCase.Params.Credential.GetNetworkCredential().password)"))
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $Headers.Authorization -eq "Basic $Base64Creds"
      }
    }
  }

  # Function to test expectations on all get requests
  Function Test-GetMethodRequirement {
    It 'Uses Get Method' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $Method -eq 'Get'
      }
    }
    It 'Has no body' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $null -eq $Body
      }
    }
  }

  # Function to test expectations on all post requests
  Function Test-PostMethodRequirement {

    if ($TestCase.BodyTests) {
      It 'Has a valid body' {

        # Verify each of the items listed in BodyTests is passed into the Invoke-RestMethod call as expected
        foreach ($Key in $TestCase.BodyTests.Keys) {
          Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
            ($Body | ConvertFrom-Json).$Key -eq $TestCase.BodyTests[$Key]
          }
        }
      }
    }
    It 'Uses Post Method' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $Method -eq 'Post'
      }
    }
    It 'Has a body' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $null -ne $Body
      }
    }
  }

# Function to test expectations on all delete requests
  Function Test-DeleteMethodRequirement {
    It 'Uses Delete Method' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $Method -eq 'Delete'
      }
    }
    It 'Has no body' {
      Assert-MockCalled Invoke-RestMethod -ModuleName $TestCase.ModuleName -ParameterFilter {
        $null -eq $Body
      }
    }
  }

  # Iterate through each test case and run the tests required for that case
  foreach($TestCase in $TestCases) {
    $Params = $TestCase.Params
    Context $TestCase.CMDLet {

      # Run Command
      & $TestCase.CMDLet @Params | Out-Null

      # Run Tests
      Test-BaseRestRequirement
      switch ($TestCase.Method) {
        'Get' {Test-GetMethodRequirement}
        'Post' {Test-PostMethodRequirement}
        'Delete' {Test-DeleteMethodRequirement}
      }
    }
  }
}