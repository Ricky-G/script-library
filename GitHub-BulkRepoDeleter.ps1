<#
    GitHub-BulkRepoDeleter.ps1

    This PowerShell script is used for mass deletion of repositories within a specific GitHub organization. 
    It leverages GitHub's REST API to fetch all repositories within the organization and then proceeds to delete each one.
    The script implements a random delay between 2 to 5 seconds between each delete operation to prevent overloading the server with requests.
    Additionally, it outputs the status of each operation, informing whether the deletion of a specific repository was successful or not. 
    In the case of an operation failure, the script prints the associated exception message, providing more context about the issue. 

    Note: Use this script with caution, as it deletes repositories permanently (it will delete all the repos in your organization so use with caution).

    Usage:
    1. Replace 'YourOrganizationName' with the name of your GitHub organization.
    2. Replace 'YourAccessToken' with your GitHub personal access token.
#>

$organizationName = "YourOrganizationName"
$token = "YourAccessToken"
$uri = "https://api.github.com/orgs/$organizationName/repos"

$headers = @{
    Authorization="token $token"
}

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

foreach ($repo in $response){
    $repoName = $repo.name
    
    try {
        $deleteUri = "https://api.github.com/repos/$organizationName/$repoName"
        Invoke-RestMethod -Uri $deleteUri -Method Delete -Headers $headers
        Write-Host "Successfully deleted repository: $repoName"
    } catch {
        Write-Host "Failed to delete repository: $repoName"
        Write-Host "Exception message: $($_.Exception.Message)"
    }

    # Random delay between 2 and 5 seconds
    $delay = Get-Random -Minimum 2 -Maximum 5
    Start-Sleep -Seconds $delay
}