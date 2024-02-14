# AzureDevOps-PipelineStats.ps1
# This PowerShell script queries the number of successful pipeline runs per day/week for all repositories within an Azure DevOps organization.

# Your organization name here
$organization = "" 

# Replace with your Personal Access Token
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":"))

# Parameters for time frame
$startDate = "2020-01-01" # Default start date
$endDate = "2024-01-31"   # Default end date

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

$projectApiUrl = "https://dev.azure.com/$organization/_apis/projects?api-version=7.1-preview.1"
$projectsResponse = Invoke-RestMethod -Uri $projectApiUrl -Headers $Headers
$projects = $projectsResponse.value

foreach ($project in $projects) {
    $projectId = $project.id
    $pipelinesApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/pipelines?api-version=6.0-preview.1"
    $pipelinesResponse = Invoke-RestMethod -Uri $pipelinesApiUrl -Headers $Headers
    $pipelines = $pipelinesResponse.value

    foreach ($pipeline in $pipelines) {
        $pipelineId = $pipeline.id
        $runsApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/pipelines/$pipelineId/runs?minTime=$startDate&maxTime=$endDate&api-version=6.0-preview.1"
        $runsResponse = Invoke-RestMethod -Uri $runsApiUrl -Headers $Headers
        $runs = $runsResponse.value

        $successfulRuns = 0
        $failedRuns = 0

        foreach ($run in $runs) {
            if ($run.result -eq "succeeded") {
                $successfulRuns += 1
            } elseif ($run.result -eq "failed") {
                $failedRuns += 1
            }
        }

        Write-Host "Pipeline: $($pipeline.name)"
        Write-Host "Total Successful Runs: $successfulRuns"
        Write-Host "Total Failed Runs: $failedRuns"
    }
}