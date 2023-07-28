<#
    GitHub-RepoPopulator.ps1

    This PowerShell script is designed to populate each repository in a GitHub organization with a README.md file. 
    The README file contains a 'Hello World' message, followed by a randomly generated string.
    
    This script provides an efficient way to quickly add a base README file to all repositories within an organization using GitHub API. 
    It is particularly useful for initial repository setup, providing basic documentation across multiple repositories.
#>

$TOKEN = "Your_Personal_Access_Token"
$ORG = "Your_GitHub_Org_Name"
$USER = "Your_GitHub_Username"
$Headers = @{
    Authorization = "token $TOKEN"
    Accept = "application/vnd.github.v3+json"
}

# Set your local directory for cloning the repositories
$localDir = "C:\_Temp\temp"
if (!(Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir | Out-Null
}

# Initialize the page variable
$page = 1

# Set per_page to the max allowed to minimize the number of requests
$perPage = 100

do {
    # Get the repositories for the current page
    $repos = Invoke-RestMethod -Uri "https://api.github.com/orgs/$ORG/repos?page=$page&per_page=$perPage" -Headers $Headers

    Write-Output "Processing page $page with $($repos.Count) repositories..."

    foreach ($repo in $repos) {
        $repoName = $repo.name

        try {
            Write-Output "Starting update of repository: $repoName"

            # Clone repository
            Set-Location -Path $localDir
            git clone -q "https://$USER`:$TOKEN@github.com/$ORG/$repoName.git"
            Set-Location -Path $repoName

            # Create README.md
            $randomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
            "Hello World $randomString" | Out-File -FilePath README.md

            # Add, commit, and push README.md
            git add README.md
            git commit -q -m "Add README.md"
            git push -q origin main

            Write-Output "Successfully updated repository: $repoName"
        }
        catch {
            Write-Output "Failed to update repository: $repoName"
            Write-Output $_.Exception.Message
        }
        finally {
            # Return to base directory and remove local repository
            Set-Location -Path $localDir
            Remove-Item -Recurse -Force -Path $repoName

            # Random delay between 2 and 5 seconds to avoid overwhelming the server or triggering rate limits
            $delay = Get-Random -Minimum 2 -Maximum 5
            Start-Sleep -Seconds $delay
        }
    }

    # Increment the page number
    $page++
} while ($repos.Count -gt 0)
