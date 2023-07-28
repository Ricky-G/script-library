# Script-Library

Script-Library is a collection of useful utility scripts in various programming languages that can be used to automate common tasks. The repository includes scripts for password cracking, archive extraction, connecting to Azure DevOps APIs, connecting and executing GitHub APIs, Unzipping .tar.gz files native using .NET and much more.

## Contributing

All contributions welcome! If you have any ideas for new scripts or improvements to existing ones, please feel free to fork the repository and submit a pull request with your changes. Appreciate all contributions, big or small!

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Files

### TFS-UniqueCommiters.ps1

This PowerShell script retrieves the list of all projects in a TFS server and then loops through each project to retrieve the list of repositories. For each repository, it retrieves the list of commits made in the repository and then creates a dictionary of unique committers across all repositories. The script requires a Personal Access Token (PAT) with appropriate permissions to access the TFS server. 

The script uses the TFS REST API to retrieve the list of projects and repositories. It then uses the Git REST API to retrieve the list of commits for each repository. 

The script is designed to work with TFS 2015 and later versions. The script requires PowerShell 3.0 or later and the Invoke-RestMethod cmdlet.

To use this script, the user must replace "http://your-tfs-server:8080/tfs" with the URL of their TFS server and "DefaultCollection" with the name of their TFS collection. The user must also replace "your-personal-access-token" with their PAT. 

### KillExistingConsoleApp.bat

This batch script kills a running instance of a console application specified by the user. The script uses the "taskkill" command to forcefully terminate the process. This script can be used to ensure that the console application is not running before starting a new instance of it. 

To use this script, the user must replace "<your-process>" with the name of the console application they want to kill. The script can be run from the command prompt or as a scheduled task.

### AzureDevOpsRepoCloner.ps1

This PowerShell script retrieves the list of all projects in an Azure DevOps organization and then loops through each project to retrieve the list of repositories. For each repository, it checks if the repository exists locally and if not, it clones the repository to a local directory. The script requires the Azure CLI and Git to be installed on the machine and a Personal Access Token (PAT) with appropriate permissions to access the Azure DevOps organization. The script clones each repository to a local directory if it doesn't exist locally. The script is designed to clone repositories for a specific project, which can be specified in the script.

### AzureDevops-UniqueCommiters.ps1

This PowerShell script retrieves the list of all projects in an Azure DevOps organization and then loops through each project to retrieve the list of repositories. For each repository, it retrieves the list of commits made in the last 90 days and then creates a dictionary of unique committers across all repositories. The script requires a Personal Access Token (PAT) with appropriate permissions to access the Azure DevOps organization.

### 7ZipArchiveCracker.ps1

This PowerShell script attempts to extract a password-protected 7-Zip archive using a list of passwords provided in a text file. The script requires 7-Zip to be installed on the machine and the path to the executable to be correct.

The script reads the list of passwords from a file and then tries each password until the archive is successfully extracted or all passwords have been tried. The script prints the password that is currently being tried and whether the archive was extracted successfully or not.

To use this script, the user must replace the paths to the archive, passwords file, and output directory with their own paths. The user must also make sure that 7-Zip is installed on their machine and the path to the executable is correct.

### GitHub-BulkRepoDeleter.ps1

This PowerShell script is used for mass deletion of repositories within a specific GitHub organization. It leverages GitHub's REST API to fetch all repositories within the organization and then proceeds to delete each one. The script implements a random delay between 2 to 5 seconds between each delete operation to prevent overloading the server with requests.
Additionally, it outputs the status of each operation, informing whether the deletion of a specific repository was successful or not. In the case of an operation failure, the script prints the associated exception message, providing more context about the issue. 

### GitHub-BulkRepoCreator.ps1

This PowerShell script is designed to simplify and automate the process of bulk repository creation on GitHub.

The script is able to create a designated number of GitHub repositories under a specific organization, following a naming pattern of 'test-repo' suffixed with a sequential number.

It takes a step further in the initialization process by not only creating the repositories but also populating each one with a unique README.md file. This file contains a 'Hello World' message, followed by a randomly generated string. The script showcases an efficient way of managing large-scale operations using GitHub API, particularly useful for demo, testing, and tutorial purposes.

### GitHub-RepoPopulator.ps1

This PowerShell script is designed to populate each repository in a GitHub organization with a README.md file. The README file contains a 'Hello World' message, followed by a randomly generated string. This script provides an efficient way to quickly add a base README file to all repositories within an organization using GitHub API. It is particularly useful for initial repository setup, providing basic documentation across multiple repositories.