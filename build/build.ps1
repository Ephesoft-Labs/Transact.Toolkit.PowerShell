# Get Module Name
$ModuleName = (Get-Item '*.psd1').Name.Replace('.psd1','')
Write-Output "Module Name: $ModuleName"

# Create Build Folder
$BuildFolder = "build/$ModuleName"
Write-Output "Build folder path: $BuildFolder"
if(!(Test-Path $BuildFolder)){
    New-Item -ItemType Directory -Path $BuildFolder
}

# Copy in Items for Release
$ItemsToRelease = @("$ModuleName.psd1", 'README.md','CHANGELOG.md','LICENSE.md', 'SECURITY.md')
foreach ($Item in $ItemsToRelease) {
  if (Test-Path $Item) {
    Write-Output "Copying $Item to $BuildFolder"
    Copy-Item -Path $Item -Destination $BuildFolder -Force
  }
}

# Module Files
Write-Output "Copying .psm1 files to build $BuildFolder"
Copy-Item -Path '*' -Destination $BuildFolder -Recurse -Include '*.psm1' -Force

# Copy in non-excluded subdirectories
$Excluded = @('build','tests')
$Directories = Get-ChildItem -Directory | Where-Object { $Excluded -notcontains $_.name }

foreach ($Directory in $Directories) {
    Write-Output "Adding directory $Directory to build folder"
    $Directory | Copy-Item -Destination $BuildFolder -Recurse -Force
}
Write-Output "Build Complete"