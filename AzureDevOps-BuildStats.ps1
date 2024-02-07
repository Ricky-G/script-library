# AzureDevOps-BuildStats.ps1
# This PowerShell script queries the number of successful builds per day/week for all repositories within an Azure DevOps organization.

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

Function Group-BuildsByDay {
    param (
        [Parameter(Mandatory = $true)]
        [array]$builds
    )

    $groupedByDay = @{}
    foreach ($build in $builds) {
        if ($build.result -eq "succeeded") {
            $finishTime = [DateTime]::Parse($build.finishTime).Date
            $groupedByDay[$finishTime] += 1
        }
    }

    return $groupedByDay
}

Function Group-BuildsByWeek {
    param (
        [Parameter(Mandatory = $true)]
        [array]$builds
    )

    $groupedByWeek = @{}
    foreach ($build in $builds) {
        if ($build.result -eq "succeeded") {
            $finishTime = [DateTime]::Parse($build.finishTime)
            $weekOfYear = Get-Date -Year $finishTime.Year -Month $finishTime.Month -Day $finishTime.Day -UFormat "%V"
            $yearWeek = "$($finishTime.Year)-W$weekOfYear"
            $groupedByWeek[$yearWeek] += 1
        }
    }

    return $groupedByWeek
}

$projectApiUrl = "https://dev.azure.com/$organization/_apis/projects?api-version=7.1-preview.1"
$projectsResponse = Invoke-RestMethod -Uri $projectApiUrl -Headers $Headers
$projects = $projectsResponse.value

foreach ($project in $projects) {
    $projectId = $project.id

    # Query builds at the project level, filtering by the result to get successful builds only
    $buildsApiUrl = "https://dev.azure.com/$organization/$projectId/_apis/build/builds?minTime=$startDate&maxTime=$endDate&api-version=7.1-preview.1&resultFilter=succeeded"
    $buildsResponse = Invoke-RestMethod -Uri $buildsApiUrl -Headers $Headers
    $builds = $buildsResponse.value

    if ($builds -and $builds.Count -gt 0) {
        $groupedByDay = Group-BuildsByDay $builds
        $groupedByWeek = Group-BuildsByWeek $builds

        Write-Host "Project: $($project.name)"
        Write-Host "Successful Builds by Day:"
        foreach ($day in $groupedByDay.Keys | Sort-Object) {
            Write-Host "$day : $($groupedByDay[$day])"
        }

        Write-Host "Successful Builds by Week:"
        foreach ($week in $groupedByWeek.Keys | Sort-Object) {
            Write-Host "$week : $($groupedByWeek[$week])"
        }
    } else {
        Write-Host "Project: $($project.name) has no successful builds in the specified time frame."
    }
}