using module .\Ephesoft.Transact.Common.psm1

<#
.Synopsis
  Gets a list of Ephesoft Transact batch classes
.Description
  Gets the list of Ephesoft Transact batch classes from a Transact instance with web services enabled
.Example
  Get-BatchClassList -Hostname 'transact.some.net' -Credential $Cred
  Connects to the Ephesoft Transact instance at https://transact.some.net and returns data on the list of batch classes available
.Example
  Get-BatchClassList -Hostname 'transact.some.net' -port 8080 -Credential $Cred -UseHTTP -AcknowledgeInsecure
  Connects to the Ephesoft Transact instance at http://transact.some.net on an insecure port (only recommended for local on-box testing) and returns data on the list of batch classes available
.Parameter Hostname
  The hostname where the transact web services API can be reached.
.Parameter Credential
  A PSCredential object containing the username/password used to connect to the Ephesoft Transact instance.
.Parameter Port
  The TCP/IP port to make the connection on if using something other than the standard HTTPS port 443.
.Parameter UseHTTP
  By default, connections are made over HTTPS.  Setting this parameter will attempt the connection over http which is only recommended for on-box testing.
.Parameter AckknowledgeInsecure
  By default, connections are made over HTTPS.  If forcing an http connection, the call will be rejected unless this parameter is specified.
#>
Function Get-TransactBatchClassList {
  [CmdLetBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter (Mandatory = $true)]
    [string] $Hostname,
    [Parameter (Mandatory = $true)]
    [pscredential] $Credential,
    [ValidateRange(1,65535)]
    [int] $Port=443,
    [switch] $UseHTTP,
    [switch] $AcknowledgeInsecure
  )

  # Prepare URL to use
  $endpoint = 'getBatchClassList'
  $uri = Get-TransactURI -Endpoint $endpoint -Port $Port -UseHTTP:$UseHTTP -AcknowledgeInsecure:$AcknowledgeInsecure -Hostname $Hostname

  # TODO - Move this into a function
  # Create Headers for REST Call
  $base64Creds = [System.Convert]::TOBase64String([System.Text.Encoding]::UTF8.GetBytes("$($Credential.Username):$($Credential.GetNetworkCredential().password)"))
  $headers = @{
    "Authorization" = "Basic $base64Creds"
  }

  # Make API Call
  Write-Progress "Getting list of batch classes from $uri"
  Write-Verbose "Getting list of batch classes from $uri"
  $response = Invoke-RestMethod -Method 'GET' -Header $headers -ContentType "application/xml" -URI $uri

  # Return array of batch class objects
  return $response.innerxml | Select-XML -XPath 'Web_Service_Result/Result_Message/Batch_Classes/BatchClass' | Select-Object -ExpandProperty Node
}

<#
.Synopsis
  Imports batch class into Ephesoft Transact
.Description
  Imports a batch class from a .zip file via the Ephesoft Transact web services API
.Example
  Import-TransactBatchClass -Hostname 'mytransactinstance.mycompany.org' -Credential $MyTransactCred -FilePath C:\PathTo\My\BatchClass1.Zip
  Uploads the BatchClass1.zip file into Transact and creates a new Batchclass named 'BatchClass1'.
.Example
  Import-TransactBatchClass -Hostname 'transact.some.net' -Credential $MyTransactCred -FilePath C:\PathTo\My\BatchClass1.Zip -port 8080 -UseHTTP -AcknowledgeInsecure
  Connects to the Ephesoft Transact instance at http://transact.some.net on an insecure port (only recommended for local on-box testing) and creates 'BatchCLass1' using 'BatchCLass1.zip'
.Parameter Credential
  A PSCredential object containing the username/password used to connect to the Ephesoft Transact instance.
.Parameter FilePath
  The full file path to the Ephesoft Transact batch class .zip file to import.
.Parameter Hostname
  The hostname where the transact web services API can be reached.
.Parameter Port
  The TCP/IP port to make the connection on if using something other than the standard HTTPS port 443.
.Parameter Priority
  The priority of the batch class in the Ephesoft Transact application.
.Parameter SharedFoldersPath
  The full file path to the Ephesoft Transact application shared folders directory.
.Parameter UseHTTP
  By default, connections are made over HTTPS.  Setting this parameter will attempt the connection over http which is only recommended for on-box testing.
.Parameter AckknowledgeInsecure
  By default, connections are made over HTTPS.  If forcing an http connection, the call will be rejected unless this parameter is specified.
#>
Function Import-TransactBatchClass {
  [CmdLetBinding()]
  [OutputType([pscustomobject])]
  param (
    [Parameter (Mandatory = $true)]
    [pscredential]$Credential,
    [Parameter (Mandatory = $true)]
    [string] $FilePath,
    [Parameter (Mandatory = $true)]
    [string] $Hostname,
    [ValidateRange(1,65535)]
    [int] $Port=443,
    [int] $Priority = 1,
    [string] $SharedFoldersPath = 'C:\Ephesoft\SharedFolders',
    [switch] $UseHTTP,
    [switch] $AcknowledgeInsecure
  )

  # Validate FilePath here to specify custom error message
  if ($FilePath -notmatch '.*\.zip$') {
    throw "Filepath parameter specified must be the full path to a .zip file containing an Ephesoft Transact batch class."
  }

  # Validate the file is found at the specified path
  if (-NOT (Test-Path $FilePath)) {
    throw "Could not find .zip file at $FilePath"
  }

  # Prepare URL to use
  $endpoint = 'importBatchClass'
  $uri = Get-TransactURI -Endpoint $endpoint -Port $Port -UseHTTP:$UseHTTP -AcknowledgeInsecure:$AcknowledgeInsecure -Hostname $Hostname

  # TODO - Move this to a common function
  # Create Headers for REST Call
  $base64Creds = [System.Convert]::TOBase64String([System.Text.Encoding]::UTF8.GetBytes("$($Credential.Username):$($Credential.GetNetworkCredential().password)"))
  $headers = @{
    "Authorization" = "Basic $base64Creds"
  }

  # Update XML Template
  $batchClassName = (Split-Path $FilePath -Leaf).Replace('.zip','')
  $XMLTemplatePath = "$PSScriptRoot\resources\importBatchClassParam.xml"
  $TempXMLPath = Update-XMLTemplate -XMLTemplatePath $XMLTemplatePath -SharedFoldersPath $SharedFoldersPath -BatchClassName $batchClassName -Priority $Priority

  # Get MultiPart Content from .zip file
  $multiPartContent = @($TempXMLPath,$FilePath) | Get-MultiPartFileContent

  # Submit request
  Write-Progress "Importing batch class $batchClassName"
  Write-Verbose "Importing batch class $batchClassName"
  $result = Invoke-RestMethod -Method 'Post' -Header $headers -ContentType "application/xml" -URI $uri -Body $multiPartContent.Content -ErrorAction 'Stop'

  return [pscustomobject] @{
    BatchClassName = $batchClassName
    StatusCode = $result.web_service_result.response_code.HTTP_CODE
    Message = $result.web_service_result.response_code.Result
  }
}

# Internal Functions
Function Update-XMLTemplate {
  [OutputType([string])]
  [CmdLetBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter (Mandatory = $true)]
    [string]$XMLTemplatePath,
    [Parameter (Mandatory = $true)]
    [string]$SharedFoldersPath,
    [Parameter (Mandatory = $true)]
    [string]$BatchClassName,
    [int]$Priority
  )

  # Update XML with Batch Class Name
  [XML]$BCXML = Get-Content $XMLTemplatePath
  $BCXML.ImportBatchClassOptions.Name = $BatchClassName
  $BCXML.ImportBatchClassOptions.Description = $BatchClassName
  $BCXML.ImportBatchClassOptions.UncFolder = "$SharedFoldersPath\$BatchClassName"

  if ($Priority) {
    $BCXML.ImportBatchClassOptions.Priority = $Priority
  }

  if ($PSCmdlet.ShouldProcess($XMLTemplatePath, 'Update Template')) {
    $TempFile = New-Item -ItemType File -Path $env:Temp -Name "tmp$((new-guid).guid.toupper().substring(0,4)).xml"
    $BCXML.Save($TempFile.FullName)
  }
  Return $TempFile.FullName
}