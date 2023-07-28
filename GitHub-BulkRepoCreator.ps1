<#
    GitHub-BulkRepoCreator.ps1

    This PowerShell script is designed to simplify and automate the process of bulk repository creation on GitHub.
    
    The script is able to create a designated number of GitHub repositories under a specific organization, 
    following a naming pattern of 'test-repo' suffixed with a sequential number.
    
    It takes a step further in the initialization process by not only creating the repositories but also populating each one with a unique README.md file. 
    This file contains a 'Hello World' message, followed by a randomly generated string.
    
    The script showcases an efficient way of managing large-scale operations using GitHub API, particularly useful for demo, testing, and tutorial purposes.
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

$startIndex = 299
$endIndex = 600

$startIndex..$endIndex | ForEach-Object {
    $repoName = "test-repo$_"
    
    # Check if repository already exists
    $existingRepo = $null
    try {
        $existingRepo = Invoke-RestMethod -Uri "https://api.github.com/repos/$ORG/$repoName" -Headers $Headers -ErrorAction Stop
    } catch {
        # Ignore errors (repository does not exist)
    }
    if ($existingRepo) {
        Write-Output "Skipping existing repository: $repoName"
        return
    }

    $Body = @{
        name = $repoName
        auto_init = $true
    } | ConvertTo-Json

    try {
        Write-Output "Creating repository: $repoName"

        # Create repository
        Invoke-RestMethod -Uri "https://api.github.com/orgs/$ORG/repos" -Method Post -Body $Body -Headers $Headers | Out-Null

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

        Write-Output "Successfully created and updated repository: $repoName"
    }
    catch {
        Write-Output "Failed to create or update repository: $repoName"
        Write-Output $_.Exception.Message
    }
    finally {
        # Return to base directory and remove local repository
        Set-Location -Path $localDir
        Remove-Item -Recurse -Force -Path $repoName

        # Random delay between 2 and 5 seconds
        $delay = Get-Random -Minimum 2 -Maximum 5
        Start-Sleep -Seconds $delay
    }
}
