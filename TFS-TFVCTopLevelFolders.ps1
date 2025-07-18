<#
TFS-TFVCTopLevelFolders.ps1

Simplified script specifically designed to list all top-level TFVC folders (repositories) across all projects.
This directly addresses the need to get TFVC repository listings similar to Git repositories.

In TFVC, repositories are represented as top-level folders under each project's root path ($/ProjectName).
This script efficiently retrieves these folders and presents them in a clear format.

Usage:
.\TFS-TFVCTopLevelFolders.ps1
#>

# Configuration - Update these values
$tfsUrl = "http://your-tfs-server:8080/tfs"  # Your TFS server URL
$collection = "DefaultCollection"  # Your TFS collection name

# Personal Access Token (keep the : prefix)
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-personal-access-token"))

$Headers = @{
    "Authorization" = $accessToken
    "Content-Type"  = "application/json"
}

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TFS TFVC Top-Level Folders Listing" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Initialize collections
$allTfvcFolders = @()
$projectsWithTfvc = 0
$totalFolderCount = 0

# Get all projects with pagination
Write-Host "Retrieving all projects..." -ForegroundColor Yellow
$projects = @()
$continuationToken = $null

do {
    $projectsUrl = "$tfsUrl/$collection/_apis/projects?api-version=5.0"
    if ($continuationToken) {
        $projectsUrl += "&continuationToken=$continuationToken"
    }
    
    try {
        $response = Invoke-WebRequest -Uri $projectsUrl -Headers $Headers -Method Get -UseBasicParsing
        $projectData = $response.Content | ConvertFrom-Json
        $projects += $projectData.value
        
        # Check for continuation token in response headers
        $continuationToken = $response.Headers["x-ms-continuationtoken"]
        
    } catch {
        Write-Host "Error: Failed to retrieve projects" -ForegroundColor Red
        Write-Host "Details: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "1. Verify your TFS URL is correct: $tfsUrl" -ForegroundColor Gray
        Write-Host "2. Ensure your PAT has the required permissions" -ForegroundColor Gray
        Write-Host "3. Remember the PAT must have a ':' colon prefix" -ForegroundColor Gray
        exit 1
    }
} while ($continuationToken)

Write-Host "Found $($projects.Count) projects" -ForegroundColor Green
Write-Host ""

# Process each project
foreach ($project in $projects) {
    $projectName = $project.name
    $projectId = $project.id
    
    Write-Progress -Activity "Scanning TFVC Folders" -Status "Processing: $projectName" -PercentComplete (($projects.IndexOf($project) / $projects.Count) * 100)
    
    # Construct TFVC root path for this project
    $tfvcRootPath = "`$/$projectName"
    
    # API endpoint to get items at one level deep
    $itemsUrl = "$tfsUrl/$collection/$projectId/_apis/tfvc/items?scopePath=$tfvcRootPath&recursionLevel=OneLevel&api-version=5.0"
    
    try {
        $itemsResponse = Invoke-RestMethod -Uri $itemsUrl -Headers $Headers -Method Get -ErrorAction SilentlyContinue
        
        if ($itemsResponse.value -and $itemsResponse.value.Count -gt 0) {
            # Filter to get only folders (not files) that are direct children of the project root
            $topLevelFolders = $itemsResponse.value | Where-Object { 
                $_.isFolder -eq $true -and 
                $_.path -ne $tfvcRootPath -and
                $_.path -match "^`\$/$projectName/[^/]+$"  # Matches only direct children
            }
            
            if ($topLevelFolders.Count -gt 0) {
                $projectsWithTfvc++
                Write-Host "Project: $projectName" -ForegroundColor Cyan
                
                foreach ($folder in $topLevelFolders) {
                    $folderName = Split-Path $folder.path -Leaf
                    $lastChange = if ($folder.changeDate) { 
                        [DateTime]::Parse($folder.changeDate).ToString("yyyy-MM-dd HH:mm") 
                    } else { 
                        "Unknown" 
                    }
                    
                    $folderInfo = [PSCustomObject]@{
                        Project = $projectName
                        FolderName = $folderName
                        FullPath = $folder.path
                        LastModified = $lastChange
                        Version = $folder.version
                        Url = $folder.url
                    }
                    
                    $allTfvcFolders += $folderInfo
                    $totalFolderCount++
                    
                    Write-Host "  📁 $folderName" -ForegroundColor Green
                    Write-Host "     Path: $($folder.path)" -ForegroundColor Gray
                    Write-Host "     Last Modified: $lastChange" -ForegroundColor Gray
                }
                Write-Host ""
            }
        }
    } catch {
        # Handle 404 errors silently (project has no TFVC content)
        if ($_.Exception.Response.StatusCode -ne 'NotFound') {
            Write-Host "Warning: Could not access TFVC for project '$projectName': $_" -ForegroundColor Yellow
        }
    }
}

Write-Progress -Activity "Scanning TFVC Folders" -Completed

# Display summary
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Total Projects Scanned: $($projects.Count)" -ForegroundColor White
Write-Host "Projects with TFVC Content: $projectsWithTfvc" -ForegroundColor White
Write-Host "Total TFVC Folders Found: $totalFolderCount" -ForegroundColor White
Write-Host ""

# Export options
$exportChoice = Read-Host "Would you like to export the results? (Y/N)"
if ($exportChoice -eq 'Y' -or $exportChoice -eq 'y') {
    Write-Host ""
    Write-Host "Export format options:" -ForegroundColor Yellow
    Write-Host "1. CSV (Excel compatible)" -ForegroundColor Gray
    Write-Host "2. JSON" -ForegroundColor Gray
    Write-Host "3. HTML Report" -ForegroundColor Gray
    
    $format = Read-Host "Select format (1-3)"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    switch ($format) {
        "1" {
            $filename = "TFVC_Folders_$timestamp.csv"
            $allTfvcFolders | Export-Csv -Path $filename -NoTypeInformation
            Write-Host "Exported to: $filename" -ForegroundColor Green
        }
        "2" {
            $filename = "TFVC_Folders_$timestamp.json"
            $allTfvcFolders | ConvertTo-Json -Depth 10 | Out-File $filename
            Write-Host "Exported to: $filename" -ForegroundColor Green
        }
        "3" {
            $filename = "TFVC_Folders_$timestamp.html"
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>TFVC Folders Report - $timestamp</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #0078d4; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .summary { background-color: #e6f3ff; padding: 10px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>TFVC Folders Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Generated:</strong> $(Get-Date)</p>
        <p><strong>TFS Server:</strong> $tfsUrl/$collection</p>
        <p><strong>Total Projects:</strong> $($projects.Count)</p>
        <p><strong>Projects with TFVC:</strong> $projectsWithTfvc</p>
        <p><strong>Total Folders:</strong> $totalFolderCount</p>
    </div>
    <table>
        <tr>
            <th>Project</th>
            <th>Folder Name</th>
            <th>Full Path</th>
            <th>Last Modified</th>
            <th>Version</th>
        </tr>
"@
            foreach ($folder in $allTfvcFolders) {
                $html += @"
        <tr>
            <td>$($folder.Project)</td>
            <td>$($folder.FolderName)</td>
            <td>$($folder.FullPath)</td>
            <td>$($folder.LastModified)</td>
            <td>$($folder.Version)</td>
        </tr>
"@
            }
            $html += @"
    </table>
</body>
</html>
"@
            $html | Out-File $filename
            Write-Host "Exported to: $filename" -ForegroundColor Green
        }
    }
}

# Display top-level summary table
if ($allTfvcFolders.Count -gt 0) {
    Write-Host ""
    Write-Host "Quick Reference Table:" -ForegroundColor Yellow
    $allTfvcFolders | Format-Table Project, FolderName, LastModified -AutoSize
}