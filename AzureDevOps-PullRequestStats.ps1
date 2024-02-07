# AzureDevOps-PullRequestStats.ps1
# This script provides a weekly breakdown of pull request stats across all projects and repositories within an Azure DevOps organization.

#Your organization name here
$organization = "" 

#Replace with your Personal Access Token (NB : the colon is required at the beginning of the token before the pat itself, so please always include the : in front of the pat)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-pat-token"))

# Parameters for time frame and pull request status
$startDate = "2023-01-01" # Default start date
$endDate = "2024-01-31"   # Default end date
$pullRequestStatus = "all" # Default status

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

Function Group-PullRequestsByWeek {
    param (
        [Parameter(Mandatory = $true)]
        [array]$pullRequests
    )

    $groupedByWeek = @{}
    foreach ($pr in $pullRequests) {
        $creationDate = [DateTime]::Parse($pr.creationDate)
        $weekOfYear = Get-Date -Year $creationDate.Year -Month $creationDate.Month -Day $creationDate.Day -UFormat "%V"
        $yearWeek = "$($creationDate.Year)-W$weekOfYear"
        $groupedByWeek[$yearWeek] += 1
    }

    return $groupedByWeek
}

$projectApiUrl = "https://dev.azure.com/$organization/_apis/projects?api-version=7.1-preview.1"
$projectsResponse = Invoke-RestMethod -Uri $projectApiUrl -Headers $Headers
$projects = $projectsResponse.value

foreach ($project in $projects) {
    $projectId = $project.id
    $repoApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/git/repositories?api-version=7.1-preview.1"
    $reposResponse = Invoke-RestMethod -Uri $repoApiUrl -Headers $Headers
    $repos = $reposResponse.value

    foreach ($repo in $repos) {
        $repoId = $repo.id
        $pullRequestsApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/git/pullrequests?searchCriteria.repositoryId=$repoId&searchCriteria.status=$pullRequestStatus&searchCriteria.minTime=$startDate&searchCriteria.maxTime=$endDate&api-version=7.1-preview.1"
        $pullRequestsResponse = Invoke-RestMethod -Uri $pullRequestsApiUrl -Headers $Headers
        $pullRequests = $pullRequestsResponse.value

        if ($pullRequests.Count -gt 0) {
            $groupedByWeek = Group-PullRequestsByWeek $pullRequests

            Write-Host "Project: $($project.name) - Repo: $($repo.name)"
            foreach ($week in $groupedByWeek.Keys | Sort-Object) {
                Write-Host "$week : $($groupedByWeek[$week])"
            }
        }
        else {
            Write-Host "Project: $($project.name) - Repo: $($repo.name) has no pull requests matching the criteria."
        }
    }
}