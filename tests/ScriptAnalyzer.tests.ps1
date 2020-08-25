Describe -Tags 'PSSA' -Name 'Testing against PSScriptAnalyzer rules' {
  Context 'PSSA Standard Rules' {
      $ScriptAnalyzerSettings = @{

        <#
          Add reason for any exclusions here
        #>
        ExcludeRules = @()
      }
      $AnalyzerIssues = Invoke-ScriptAnalyzer -Path ".\*" -Settings $ScriptAnalyzerSettings
      $ScriptAnalyzerRuleNames = Get-ScriptAnalyzerRule | Select-Object -ExpandProperty RuleName
      foreach ($Rule in $ScriptAnalyzerRuleNames) {
          $Skip = @{Skip=$False}
          if ($ScriptAnalyzerSettings.ExcludeRules -contains $Rule) {
              # We still want it in the tests, but since it doesn't actually get tested we will skip
              $Skip = @{Skip = $True}
          }

          It "Should pass $Rule" @Skip {
              $Failures = $AnalyzerIssues | Where-Object -Property RuleName -eq -Value $rule
              ($Failures | Measure-Object).Count | Should Be 0
          }
      }
  }
}