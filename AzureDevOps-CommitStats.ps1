# AzureDevOps-CommitStats.ps1
# This PowerShell script queries the number of commits per day/week for all repositories within an Azure DevOps organization.

#Your organization name here
$organization = "" 

#Replace with your Personal Access Token (NB : the colon is required at the beginning of the token before the pat itself, so please always include the : in front of the pat)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-pat-token"))

# Parameters for time frame
$startDate = "2020-01-01" # Default start date
$endDate = "2024-01-31"   # Default end date

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

Function Group-CommitsByDay {
    param (
        [Parameter(Mandatory = $true)]
        [array]$commits
    )

    $groupedByDay = @{}
    foreach ($commit in $commits) {
        $commitDate = [DateTime]::Parse($commit.committer.date).Date
        $groupedByDay[$commitDate] += 1
    }

    return $groupedByDay
}

Function Group-CommitsByWeek {
    param (
        [Parameter(Mandatory = $true)]
        [array]$commits
    )

    $groupedByWeek = @{}
    foreach ($commit in $commits) {
        $commitDate = [DateTime]::Parse($commit.committer.date)
        $weekOfYear = Get-Date -Year $commitDate.Year -Month $commitDate.Month -Day $commitDate.Day -UFormat "%V"
        $yearWeek = "$($commitDate.Year)-W$weekOfYear"
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
        $commitsApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/git/repositories/$repoId/commits?searchCriteria.fromDate=$startDate&searchCriteria.toDate=$endDate&api-version=7.1-preview.1"
        $commitsResponse = Invoke-RestMethod -Uri $commitsApiUrl -Headers $Headers
        $commits = $commitsResponse.value

        if ($commits -and $commits.Count -gt 0) {
            $groupedByDay = Group-CommitsByDay $commits
            $groupedByWeek = Group-CommitsByWeek $commits

            Write-Host "Repository: $($project.name)-$($repo.name)"
            Write-Host "Commits by Day:"
            foreach ($day in $groupedByDay.Keys | Sort-Object) {
                Write-Host "$day : $($groupedByDay[$day])"
            }

            Write-Host "Commits by Week:"
            foreach ($week in $groupedByWeek.Keys | Sort-Object) {
                Write-Host "$week : $($groupedByWeek[$week])"
            }
        } else {
            Write-Host "Repository: $($project.name)-$($repo.name) has no commits in the specified time frame."
        }
    }
}
