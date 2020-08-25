# This internal function returns the formatted URI for the Transact instance
Function Get-TransactURI {
  [CmdLetBinding()]
  [OutputType([string])]
  param (
    [Parameter (Mandatory = $true)]
    [string] $Hostname,
    [Parameter (Mandatory = $true)]
    [string] $Endpoint,
    [ValidateRange(1,65535)]
    [int] $Port,
    [switch] $UseHTTP,
    [switch] $AcknowledgeInsecure
  )
    # Prepare URL to use
    $Hostname += ":$Port"
    $protocol = 'https://'
    if ($UseHTTP) {
      if ($AcknowledgeInsecure) {
        $protocol = 'http://'
      }
      else {
        throw 'UseHTTP specified which will send credentials insecurely to target server. To force the insecure connection add the AcknowledgeInsecure switch.  WARNING: This should only be done in on-box development/testing scenarios.'
      }
    }
    return "$protocol$Hostname/dcma/rest/$Endpoint"
}

# This internal function returns correctly formatted multipart file content
Function Get-MultiPartFileContent {
  [CMDLetBinding()]
  param (
    [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
    [string] $FilePath
  )
  begin {
    # Create Multipart form data content object
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
  }

  process {
    # Create file stream
    $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
    [array]$fileStreams += $fileStream

    # Create file header
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileHeader.Name = (Get-ChildItem $FilePath).name
    $fileHeader.FileName = "$FilePath"

    # Create file content
    $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader

    # Add this file's content to the multipart form data
    $multipartContent.Add($fileContent)
  }
  end {

    # Note that the multipart content type is passed as an array unless it is wrapped in another object
    return [pscustomobject] @{
      Content = $multipartContent
      FileStreams = $fileStreams
    }
  }
}
