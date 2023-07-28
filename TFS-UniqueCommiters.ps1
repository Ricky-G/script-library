<#
TFS-UniqueCommiters.ps1

This PowerShell script retrieves the list of all projects in a TFS server and then loops through each project to retrieve the list of repositories. For each repository, 
it retrieves the list of commits made in the repository and then creates a dictionary of unique committers across all repositories. 
The script requires a Personal Access Token (PAT) with appropriate permissions to access the TFS server. 

The script uses the TFS REST API to retrieve the list of projects and repositories. It then uses the Git REST API to retrieve the list of commits for each repository. 

The script is designed to work with TFS 2015 and later versions. The script requires PowerShell 3.0 or later and the Invoke-RestMethod cmdlet.

To use this script, the user must replace "http://your-tfs-server:8080/tfs" with the URL of their TFS server and "DefaultCollection" with the name of their TFS collection. 
The user must also replace "your-personal-access-token" with their PAT. 
#>

$tfsUrl = "http://your-tfs-server:8080/tfs"  # Replace with your TFS server URL
$collection = "DefaultCollection"  # Replace with your TFS collection name

#Replace with your Personal Access Token (NB : the colon is required at the beginning of the token before the pat itself, so please always include the : in front of the pat)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-personal-access-token"))

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

# Get all projects
$pageSize = 100
$skipCount = 0
$projects = @()

do {
    $pagedApiUrl = "$tfsUrl/$collection/_apis/projects?`$top=$pageSize&`$skip=$skipCount"
    try {
        $projectsResponse = Invoke-RestMethod -Uri $pagedApiUrl -Headers $Headers -ContentType 'application/json' -ErrorAction Stop
        $fetchedProjects = $projectsResponse.value
    } catch {
        Write-Host "Error: The API call was not successful. Response:`n$($_.Exception.Response)"
        exit
    }

    # Check if the response has the expected properties
    if ($null -eq $fetchedProjects -or $fetchedProjects.Count -eq 0 -or (-not ($fetchedProjects[0].PSObject.Properties.Name -contains 'id'))) {
        Write-Host "Error: The response for the first API call to get a list of all projects is not valid. Please check your Personal Access Token, remember the PAT token needs to have a : colon in front of it, please check it has that."
        exit
    }

    $projects += $fetchedProjects
    $skipCount += $pageSize
} while ($fetchedProjects.Count -eq $pageSize)

$uniqueCommitters = @{}

foreach ($project in $projects) {
    $projectName = $project.name
    $repoApiUrl = "$tfsUrl/$collection/$projectName/_apis/git/repositories"
    $reposResponse = Invoke-RestMethod -Uri $repoApiUrl -Headers $Headers
    $repos = $reposResponse.value

    foreach ($repo in $repos) {
        $repoId = $repo.id
        $fromDate = (Get-Date).AddDays(-90).ToString("yyyy-MM-dd")
        $commitsApiUrl = "$tfsUrl/$collection/$projectName/_apis/git/repositories/$repoId/commits?searchCriteria.fromDate=$fromDate"
        $commitsResponse = Invoke-RestMethod -Uri $commitsApiUrl -Headers $Headers
        $commits = $commitsResponse.value

        foreach ($commit in $commits) {
            $committer = $commit.committer.name
            $uniqueCommitters[$committer] = $true
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