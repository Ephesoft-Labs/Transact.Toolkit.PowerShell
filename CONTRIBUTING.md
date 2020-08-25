# Contributing
When contributing to this repository, all changes must be on a new branch which goes through a pull request process.  If there is an open story for this work the branch name should start with the story name.

## Versioning
Update the version number of the module in the .psd1 for each change by following Semantic versioning guidelines (https://semver.org/).
Update the ChangeLog.md file with the new version and a brief summary of changes.

## Linting
Lint the code prior to submitting a pull request by running Invoke-ScriptAnalyzer on the module path.

## Testing
Changes including logic should be accompanied by a pester test.  All other changes should be manually tested.

## Metadata
All exported cmdlets/functions should have metadata which includes examples and parameter help.

## Pull Request Process
You may merge the Pull Request in once you have the necessary number of approvals for the repository.