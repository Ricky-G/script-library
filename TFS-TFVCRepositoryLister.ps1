<#
TFS-TFVCRepositoryLister.ps1

This PowerShell script retrieves the list of all TFVC repositories (top-level folders) in a TFS/Azure DevOps Server instance.
Unlike Git where repositories are distinct entities, TFVC uses a folder-based structure where "repositories" are typically 
top-level folders under each project's TFVC root path.

The script requires a Personal Access Token (PAT) with appropriate permissions to access the TFS server.
It uses the TFVC Items REST API to traverse the folder structure and identify repositories.

The script is designed to work with TFS 2015 and later versions, including Azure DevOps Server.
It requires PowerShell 3.0 or later and the Invoke-RestMethod cmdlet.

To use this script:
1. Replace "http://your-tfs-server:8080/tfs" with your TFS server URL
2. Replace "DefaultCollection" with your TFS collection name
3. Replace "your-personal-access-token" with your PAT (keep the : prefix)
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("None", "OneLevel", "Full")]
    [string]$RecursionLevel = "OneLevel",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeEmptyFolders = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowItemCount = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "Table" # Table, Json, CSV
)

# Configuration
$tfsUrl = "http://your-tfs-server:8080/tfs"  # Replace with your TFS server URL
$collection = "DefaultCollection"  # Replace with your TFS collection name

# Replace with your Personal Access Token (NB: the colon is required at the beginning)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-personal-access-token"))

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

# Initialize result collection
$tfvcRepositories = @()

Write-Host "Connecting to TFS Server: $tfsUrl/$collection" -ForegroundColor Cyan
Write-Host "Recursion Level: $RecursionLevel" -ForegroundColor Cyan
Write-Host ""

# Get all projects
$pageSize = 100
$skipCount = 0
$projects = @()

Write-Host "Fetching all projects..." -ForegroundColor Yellow

do {
    $pagedApiUrl = "$tfsUrl/$collection/_apis/projects?`$top=$pageSize&`$skip=$skipCount&api-version=5.0"
    try {
        $projectsResponse = Invoke-RestMethod -Uri $pagedApiUrl -Headers $Headers -Method Get -ErrorAction Stop
        $fetchedProjects = $projectsResponse.value
    } catch {
        Write-Host "Error: Failed to fetch projects. Response:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Please check your TFS URL and Personal Access Token (remember the PAT needs a : colon prefix)" -ForegroundColor Yellow
        exit 1
    }

    if ($null -eq $fetchedProjects -or $fetchedProjects.Count -eq 0) {
        if ($projects.Count -eq 0) {
            Write-Host "Error: No projects found or invalid response" -ForegroundColor Red
            exit 1
        }
        break
    }

    $projects += $fetchedProjects
    $skipCount += $pageSize
} while ($fetchedProjects.Count -eq $pageSize)

Write-Host "Found $($projects.Count) projects" -ForegroundColor Green
Write-Host ""

# Process each project
foreach ($project in $projects) {
    $projectName = $project.name
    Write-Host "Processing project: $projectName" -ForegroundColor Cyan
    
    # Check if project has TFVC content by querying the root path
    $tfvcRootPath = "`$/$projectName"
    $tfvcApiUrl = "$tfsUrl/$collection/$projectName/_apis/tfvc/items?scopePath=$tfvcRootPath&recursionLevel=$RecursionLevel&api-version=5.0"
    
    try {
        $tfvcResponse = Invoke-RestMethod -Uri $tfvcApiUrl -Headers $Headers -Method Get -ErrorAction Stop
        $tfvcItems = $tfvcResponse.value
        
        if ($null -eq $tfvcItems -or $tfvcItems.Count -eq 0) {
            Write-Host "  No TFVC content found in project" -ForegroundColor Gray
            continue
        }
        
        # Filter for folders only (excluding files)
        $folders = $tfvcItems | Where-Object { $_.isFolder -eq $true }
        
        # Get root folder info
        $rootFolder = $folders | Where-Object { $_.path -eq $tfvcRootPath }
        
        if ($RecursionLevel -eq "None") {
            # Just show the project root if it exists
            if ($rootFolder) {
                $repoInfo = [PSCustomObject]@{
                    Project = $projectName
                    Path = $rootFolder.path
                    Type = "Project Root"
                    LastChangeDate = $rootFolder.changeDate
                    Version = $rootFolder.version
                }
                $tfvcRepositories += $repoInfo
            }
        } else {
            # Get immediate child folders (these are typically the "repositories")
            $childFolders = $folders | Where-Object { 
                $_.path -ne $tfvcRootPath -and 
                $_.path -match "^`\$/$projectName/[^/]+$"
            }
            
            foreach ($folder in $childFolders) {
                $itemCount = 0
                
                if ($ShowItemCount) {
                    # Get item count for this folder
                    $countUrl = "$tfsUrl/$collection/$projectName/_apis/tfvc/items?scopePath=$($folder.path)&recursionLevel=Full&api-version=5.0"
                    try {
                        $countResponse = Invoke-RestMethod -Uri $countUrl -Headers $Headers -Method Get -ErrorAction SilentlyContinue
                        $itemCount = $countResponse.count
                    } catch {
                        $itemCount = -1
                    }
                }
                
                $repoInfo = [PSCustomObject]@{
                    Project = $projectName
                    Repository = $folder.path.Substring($tfvcRootPath.Length + 1)
                    FullPath = $folder.path
                    LastChangeDate = $folder.changeDate
                    Version = $folder.version
                    ItemCount = if ($ShowItemCount) { $itemCount } else { "N/A" }
                }
                
                if (!$IncludeEmptyFolders -and $itemCount -eq 0) {
                    continue
                }
                
                $tfvcRepositories += $repoInfo
                Write-Host "  Found repository: $($repoInfo.Repository)" -ForegroundColor Green
            }
            
            if ($childFolders.Count -eq 0) {
                Write-Host "  No top-level folders found" -ForegroundColor Gray
            }
        }
        
    } catch {
        if ($_.Exception.Response.StatusCode -eq 'NotFound') {
            Write-Host "  No TFVC content in this project" -ForegroundColor Gray
        } else {
            Write-Host "  Error accessing TFVC for project: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "Total TFVC repositories found: $($tfvcRepositories.Count)" -ForegroundColor Green
Write-Host ""

# Output results based on format
switch ($OutputFormat) {
    "Table" {
        if ($tfvcRepositories.Count -gt 0) {
            $tfvcRepositories | Format-Table -AutoSize
        }
    }
    "Json" {
        $tfvcRepositories | ConvertTo-Json -Depth 10
    }
    "CSV" {
        $tfvcRepositories | Export-Csv -Path "TFVCRepositories.csv" -NoTypeInformation
        Write-Host "Results exported to TFVCRepositories.csv" -ForegroundColor Green
    }
    default {
        $tfvcRepositories
    }
}

# Additional statistics
if ($tfvcRepositories.Count -gt 0) {
    Write-Host ""
    Write-Host "Repository Statistics:" -ForegroundColor Yellow
    $projectsWithTFVC = ($tfvcRepositories | Select-Object -Unique Project).Count
    Write-Host "Projects with TFVC content: $projectsWithTFVC" -ForegroundColor Cyan
    
    $reposByProject = $tfvcRepositories | Group-Object Project
    Write-Host ""
    Write-Host "Repositories per project:" -ForegroundColor Yellow
    $reposByProject | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) repositories" -ForegroundColor Cyan
    }
}