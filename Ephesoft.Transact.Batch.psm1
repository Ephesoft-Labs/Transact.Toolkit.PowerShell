using module .\Ephesoft.Transact.Common.psm1

<#
.Synopsis
  Submits a batch class
.Description
  Submit a .zip file containing documents to be processed by an existing batch class
.Example
  Submit-TransactBatch -Credential $Cred -FilePath C:\Path\To\Batch1.zip -BatchClassName 'MyBatchClass' -Hostname 'MyTransactServer.com'
  Connects to the Ephesoft Transact instance at https://MyTransactServer.com and uploads Batch1.zip as a batch to be processed by the 'MyBatchClass' batch class.
.Example
  Submit-TransactBatch -Credential $Cred -FilePath 'C:\MyBatch1.zip' -BatchClassName 'MyBatchClass' -Hostname 'transact.some.net' -port 8080 -UseHTTP -AcknowledgeInsecure
  Connects to the Ephesoft Transact instance at http://transact.some.net on an insecure port (only recommended for local on-box testing) and submits batch 'MyBatch1.zip' to 'MyBatchClass'

.Parameter Credential
  A PSCredential object containing the username/password used to connect to the Ephesoft Transact instance.
.Parameter FilePath
  The full windows filepath to the batch .zip file to be submitted.  The file may contain multiple documents for processing.
.Parameter BatchClassName
  Name of the existing batch class in the Ephesoft Transact application that will process the submitted batch.
.Parameter Hostname
  The hostname where the transact web services API can be reached.
.Parameter Port
  The TCP/IP port to make the connection on if using something other than the standard HTTPS port 443.
.Parameter UseHTTP
  By default, connections are made over HTTPS.  Setting this parameter will attempt the connection over http which is only recommended for on-box testing.
.Parameter AckknowledgeInsecure
  By default, connections are made over HTTPS.  If forcing an http connection, the call will be rejected unless this parameter is specified.
#>
Function Submit-TransactBatch {
  param (
    [Parameter (Mandatory = $true)]
    [pscredential]$Credential,
    [Parameter (Mandatory = $true)]
    [string] $FilePath,
    [Parameter (Mandatory = $true)]
    [string] $BatchClassName,
    [Parameter (Mandatory = $true)]
    [string] $Hostname,
    [ValidateRange(1,65535)]
    [int] $Port=443,
    [switch] $UseHTTP,
    [switch] $AcknowledgeInsecure
  )

  # TODO - Put this into a common function
  # Prepare authorization headers
  $headers = @{"Authorization" = "Basic " + [System.Convert]::TOBase64String([System.Text.Encoding]::UTF8.GetBytes("$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"))}

  # Validate FilePath here to specify custom error message
  if ($FilePath -notmatch '.*\.zip$') {
    throw "Filepath parameter specified must be the full path to a .zip file containing an Ephesoft Transact batch class."
  }

  if (-NOT (Test-Path $FilePath)) {
    throw "Could not find batch file at specified path $FilePath"
  }

  # Get Batch Class ID
  $batchName = (Split-Path $FilePath -Leaf) -replace('.zip','')
  $Params = @{
    Credential = $Credential
    Hostname = $Hostname
    Port = $Port
    UseHTTP = $UseHTTP
    AcknowledgeInsecure = $AcknowledgeInsecure
  }
  $batchClassID = (Get-TransactBatchCLassList @Params | Where-Object {$_.Name -eq $BatchClassName}).Identifier

  # Validate batch class name exists
  if (-NOT $batchClassID) {
    throw "Could not find existing batch class with name $BatchClassName"
  }

  # URL encode batch name and batch class ID before using in endpoint
  $encoded_BatchName = [System.Web.HTTPUtility]::UrlEncode($BatchName)
  $encoded_BatchClassID = [System.Web.HTTPUtility]::UrlEncode($batchClassID)

  # Prepare URL to use
  $endpoint = "uploadBatch/$encoded_BatchClassID/$encoded_BatchName"
  $uri = Get-TransactURI -Endpoint $endpoint -Port $Port -UseHTTP:$UseHTTP -AcknowledgeInsecure:$AcknowledgeInsecure -Hostname $Hostname

  # Get multipart content for all files in the batches' .zip file
  $multiPartFileContent = $FilePath | Get-MultiPartFileContent

  # Submit request
  Write-Progress "Submitting batch $batchName from file $FilePath"
  Write-Verbose "Submitting batch $batchName from file $FilePath"
  $result = Invoke-RestMethod $uri -Method 'POST' -Headers $headers -Body $multiPartFileContent.Content -SkipCertificateCheck -ContentType "application/xml" -ErrorAction 'Stop'

  $return = [pscustomobject] @{
    BatchClassName = $BatchClassName
    BatchName = $batchName
    StatusCode = $result.web_service_result.response_code.HTTP_CODE
    Message = "$($result.web_service_result.response_code.Result)"
  }

  return $return
}