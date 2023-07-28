# AzureDevops-UniqueCommiters.ps1
# This PowerShell script retrieves the list of all projects in an Azure DevOps organization and then loops through each project to retrieve the list of repositories. 
# For each repository, it retrieves the list of commits made in the last 90 days and then creates a dictionary of unique committers across all repositories. 
# The script requires a Personal Access Token (PAT) with appropriate permissions to access the Azure DevOps organization.


#Your organization name here
$organization = "" 

#Replace with your Personal Access Token (NB : the colon is required at the beginning of the token before the pat itself, so please always include the : in front of the pat)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-pat-token"))

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

# Get all projects
$projectApiUrl = "https://dev.azure.com/$organization/_apis/projects"
try {
    $projectsResponse = Invoke-RestMethod -Uri $projectApiUrl -Headers $Headers -ContentType 'application/json' -ErrorAction Stop
    $projects = $projectsResponse.value
} catch {
    Write-Host "Error: The API call was not successful. Response:`n$($_.Exception.Response)"
    exit
}

# Check if the response has the expected properties
if ($null -eq $projects -or $projects.Count -eq 0 -or (-not ($projects[0].PSObject.Properties.Name -contains 'id'))) {
    Write-Host "Error: The response for the first API call to get a list of all projects is not valid. Please check your Personal Access Token, remember the PAT token needs to have a : colon in front of it, please check it has that."
    exit
}

$uniqueCommitters = @{}

#Loop through each project
foreach ($project in $projects) {
    $projectId = $project.id
    $repoApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/git/repositories"
    $reposResponse = Invoke-RestMethod -Uri $repoApiUrl -Headers $Headers
    $repos = $reposResponse.value

    #Loop through each repo
    foreach ($repo in $repos) {
        $repoId = $repo.id
        $fromDate = (Get-Date).AddDays(-90).ToString("yyyy-MM-dd") #Commiter history for the last 90 days
        $commitsApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/git/repositories/$repoId/commits?searchCriteria.fromDate=$fromDate"
        $commitsResponse = Invoke-RestMethod -Uri $commitsApiUrl -Headers $Headers
        $commits = $commitsResponse.value

        foreach ($commit in $commits) {
            $committer = $commit.committer.name
            $committerEmail = $commit.committer.email
            $lastCommitDate = $commit.committer.date
        
            # For each committer, store their email and the date of their last commit in the hashtable
            $uniqueCommitters[$committer] = @{
                Email = $committerEmail
                LastCommitDate = $lastCommitDate
            }
        }
    }
}

# Check if the uniqueCommitters hashtable is empty
if ($uniqueCommitters.Count -eq 0) {
    Write-Host "No committers found for the given time frame"
} else {
    # Output unique committers
    $uniqueCommitters.Keys | Sort-Object | ForEach-Object {
        Write-Host "Name: $_ | Email: $($uniqueCommitters[$_].Email) | Last Commit Date: $($uniqueCommitters[$_].LastCommitDate)"
    }
}