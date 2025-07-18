# Script-Library

Script-Library is a collection of useful utility scripts in various programming languages that can be used to automate common tasks. The repository includes scripts for password cracking, archive extraction, connecting to Azure DevOps APIs, connecting and executing GitHub APIs, exploring TFS TFVC repositories, unzipping .tar.gz files native using .NET and much more.

## 📊 Script Overview

| Category | Script | Purpose | Language |
|----------|--------|---------|----------|
| **🔧 TFS/TFVC** | [`TFS-TFVCTopLevelFolders.ps1`](#tfs-tfvctoplevelfolders.ps1) | List all top-level TFVC folders across projects | PowerShell |
| | [`TFS-TFVCRepositoryLister.ps1`](#tfs-tfvcrepositorylister.ps1) | Configurable TFVC folder discovery | PowerShell |
| | [`TFS-TFVCRepositoryExplorer.ps1`](#tfs-tfvcrepositoryexplorer.ps1) | Advanced TFVC exploration with tree view | PowerShell |
| | [`TFS-UniqueCommiters.ps1`](#tfs-uniquecommiters.ps1) | Find unique committers across TFS repositories | PowerShell |
| **☁️ Azure DevOps** | [`AzureDevOps-RepoCloner.ps1`](#azuredevopsrepocloner.ps1) | Clone all repositories from Azure DevOps org | PowerShell |
| | [`AzureDevops-UniqueCommiters.ps1`](#azuredevops-uniquecommiters.ps1) | Find unique committers in Azure DevOps | PowerShell |
| | [`AzureDevOps-BuildStats.ps1`](#azuredevops-buildstats.ps1) | Analyze build statistics and metrics | PowerShell |
| | [`AzureDevOps-CommitStats.ps1`](#azuredevops-commitstats.ps1) | Analyze commit statistics and patterns | PowerShell |
| | [`AzureDevOps-PipelineStats.ps1`](#azuredevops-pipelinestats.ps1) | Analyze pipeline performance metrics | PowerShell |
| | [`AzureDevOps-PullRequestStats.ps1`](#azuredevops-pullrequeststats.ps1) | Analyze pull request statistics | PowerShell |
| **🐙 GitHub** | [`GitHub-BulkRepoCreator.ps1`](#github-bulkrepocreator.ps1) | Bulk create GitHub repositories | PowerShell |
| | [`GitHub-BulkRepoDeleter.ps1`](#github-bulkrepodeleter.ps1) | Bulk delete GitHub repositories | PowerShell |
| | [`GitHub-RepoPopulator.ps1`](#github-repopopulator.ps1) | Populate repositories with README files | PowerShell |
| **📊 Azure Monitoring** | [`SendCustomLogDataToLogAnalytics.ps1`](#sendcustomlogdatatologanalytics.ps1) | Send custom data to Azure Log Analytics | PowerShell |
| **🔐 Security/Utilities** | [`7ZipArchiveCracker.ps1`](#7ziparchivecracker.ps1) | Password crack 7-Zip archives | PowerShell |
| | [`KillExistingConsoleApp.bat`](#killexistingconsoleapp.bat) | Terminate running console applications | Batch |

## Contributing

All contributions welcome! If you have any ideas for new scripts or improvements to existing ones, please feel free to fork the repository and submit a pull request with your changes. Appreciate all contributions, big or small!

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Files

### TFS TFVC Repository Scripts (New!)

A comprehensive collection of PowerShell scripts for exploring and managing Team Foundation Version Control (TFVC) repositories in TFS/Azure DevOps Server. These scripts solve the challenge of listing and analyzing TFVC folder structures, which differ significantly from Git's repository model.

#### TFS-TFVCTopLevelFolders.ps1
Quick and simple script to list all top-level TFVC folders across all projects. Features interactive export options (CSV, JSON, HTML) and progress tracking. Perfect for getting a quick overview of all TFVC repositories in your TFS instance.

#### TFS-TFVCRepositoryLister.ps1
Configurable script with command-line parameters for customized TFVC folder discovery. Supports multiple recursion levels, item count statistics, and various output formats. Ideal for automated reporting and CI/CD integration.

#### TFS-TFVCRepositoryExplorer.ps1
Advanced exploration tool with tree view visualization, pattern-based filtering, and change history tracking. Supports deep folder traversal with configurable depth limits. Best for detailed repository analysis and finding specific folder structures.

See [TFS-TFVC-Scripts-README.md](TFS-TFVC-Scripts-README.md) for detailed documentation and usage examples.

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

### SendCustomLogDataToLogAnalytics.ps1

This PowerShell script is designed to send custom log data to Azure Log Analytics. It uses the Log Analytics Data Collector API to send custom log data to a Log Analytics workspace. The script requires a Log Analytics workspace ID and a Log Analytics workspace key. The script also requires the name of the log type and the log data to be sent to the workspace. The script can be used to send custom log data to Log Analytics.