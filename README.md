# Ephesoft Transact Powershell

This repository contains PowerShell cmdlets for developers and administrators to develop, deploy, and manage the Ephesoft Transact application.

## Installation

### [PowerShell Gallery](https://www.powershellgallery.com/)

Run the following command in an elevated PowerShell session to install the module for Ephesoft Transact CMDlets:

```powershell
Install-Module -Name Ephesoft.Transact
```

This module runs on Windows PowerShell 7.0 or greater.

If you have an earlier version of the Ephesoft Transact PowerShell module installed from the PowerShell Gallery and would like to update to the latest version, run the following command in an elevated PowerShell session:

```powershell
Update-Module -Name Ephesoft.Transact
```

`Update-Module` installs the new version side-by-side with previous versions. It does not uninstall the previous versions.

## Usage

### Discovering cmdlets

Use the `Get-Command` cmdlet to discover cmdlets within a specific module, or cmdlets that follow a specific search pattern:

```powershell
# List all cmdlets in the Ephesoft.Transact module
Get-Command -Module Ephesoft.Transact

# List all cmdlets that contain TransactBatch
Get-Command -Name '*TransactBatch*'
```

### Cmdlet help and examples

To view the help content for a cmdlet, use the `Get-Help` cmdlet:

```powershell
# View the basic help content for Get-TransactBatchClassList
Get-Help -Name Get-TransactBatchClassList

# View the examples for Import-TransactBatchClass
Get-Help -Name Import-TransactBatchClass -Examples

# View the full help content for Submit-TransactBatch
Get-Help -Name Submit-TransactBatch -Full
```

## Contributing
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file

## License
Please see the [LICENSE.md](LICENSE.md) file

## ChangeLog
Please see the [CHANGELOG.md](CHANGELOG.md) file