<#
AzureDevOpsRepoCloner.ps1

This PowerShell script retrieves the list of all projects in an Azure DevOps organization and then loops through each project to retrieve the list of repositories. 
For each repository, it checks if the repository exists locally and if not, it clones the repository to a local directory. 
The script requires the Azure CLI and Git to be installed on the machine and a Personal Access Token (PAT) with appropriate permissions to access the Azure DevOps organization. 

The script also checks if the Azure CLI and Git are installed on the machine and if not, it installs them. 
It then checks if the Azure DevOps extension is installed and if not, it installs it. 

The script clones each repository to a local directory if it doesn't exist locally. The script is designed to clone repositories for a specific project, 
which can be specified in the script.
#>

param(
    [string]$Organization
)

$Organization = "https://dev.azure.com/<your-organization>"

# Make sure we are signed in to Azure
$AccountInfo = az account show 2>&1
try {
    $AccountInfo = $AccountInfo | ConvertFrom-Json -ErrorAction Stop
}
catch {
    az login --allow-no-subscriptions
}

# Make sure we have Azure DevOps extension installed
$DevOpsExtension = az extension list --query '[?name == ''azure-devops''].name' -o tsv
if ($null -eq $DevOpsExtension) {
    $null = az extension add --name 'azure-devops'
}

$Projects = az devops project list --organization $Organization --query 'value[].name' -o tsv
foreach ($Proj in $Projects) {
    if (($Proj -eq "your-project")){

        if (-not (Test-Path -Path ".\$Proj" -PathType Container)) {
            New-Item -Path $Proj -ItemType Directory |
            Select-Object -ExpandProperty FullName |
            Push-Location
        }
        $Repos = az repos list --organization $Organization --project $Proj | ConvertFrom-Json
        foreach ($Repo in $Repos) {
            Start-Sleep -s 10

            if(-not (Test-Path -Path $Repo.name -PathType Container)) {
                Write-Warning -Message "Cloning repo $Proj\$($Repo.Name)"
                git clone $Repo.webUrl "C:\_Projects\test\$($Repo.Name)"
            }
        }
    }    
}
