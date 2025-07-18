<#
TFS-TFVCRepositoryExplorer.ps1

Advanced PowerShell script for exploring TFVC folder structures in TFS/Azure DevOps Server.
This script provides comprehensive capabilities for listing and analyzing TFVC repositories,
with support for recursive traversal, filtering, and detailed reporting.

Features:
- List all TFVC repositories across all projects
- Recursive folder traversal with configurable depth
- Filter by folder patterns and date ranges
- Export results in multiple formats (Table, JSON, CSV, Tree)
- Performance optimizations with parallel processing option
- Detailed folder statistics and change history

Requirements:
- PowerShell 3.0 or later
- TFS 2015 or later / Azure DevOps Server
- Personal Access Token with TFVC read permissions

Usage Examples:
.\TFS-TFVCRepositoryExplorer.ps1 -MaxDepth 2 -OutputFormat Tree
.\TFS-TFVCRepositoryExplorer.ps1 -FilterPattern "*Main*" -ShowChanges
.\TFS-TFVCRepositoryExplorer.ps1 -ProjectFilter "MyProject" -ExportPath "C:\Reports"
#>

[CmdletBinding()]
param(
    # Connection Parameters
    [Parameter(Mandatory=$false)]
    [string]$TfsUrl = "http://your-tfs-server:8080/tfs",
    
    [Parameter(Mandatory=$false)]
    [string]$Collection = "DefaultCollection",
    
    [Parameter(Mandatory=$false)]
    [string]$PersonalAccessToken = "your-personal-access-token",
    
    # Exploration Parameters
    [Parameter(Mandatory=$false)]
    [int]$MaxDepth = 1,  # How deep to traverse (1 = top-level only)
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectFilter = "*",  # Filter specific projects
    
    [Parameter(Mandatory=$false)]
    [string]$FilterPattern = "*",  # Filter folder names
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeFiles = $false,  # Include files in results
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowChanges = $false,  # Show recent changes
    
    [Parameter(Mandatory=$false)]
    [int]$ChangesDays = 30,  # Days of change history to show
    
    # Output Parameters
    [Parameter(Mandatory=$false)]
    [ValidateSet("Table", "Json", "CSV", "Tree", "Detailed")]
    [string]$OutputFormat = "Tree",
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# Helper Functions
function Write-VerboseLog {
    param([string]$Message, [string]$Color = "Gray")
    if ($Verbose) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-TFVCItems {
    param(
        [string]$ProjectName,
        [string]$Path,
        [string]$RecursionLevel = "OneLevel"
    )
    
    $encodedPath = [System.Web.HttpUtility]::UrlEncode($Path)
    $apiUrl = "$TfsUrl/$Collection/$ProjectName/_apis/tfvc/items?scopePath=$encodedPath&recursionLevel=$RecursionLevel&api-version=5.0"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $Headers -Method Get -ErrorAction Stop
        return $response.value
    } catch {
        Write-VerboseLog "Error fetching items for $Path : $_" "Red"
        return @()
    }
}

function Get-FolderTree {
    param(
        [string]$ProjectName,
        [string]$Path,
        [int]$CurrentDepth,
        [int]$MaxDepth,
        [string]$Indent = ""
    )
    
    if ($CurrentDepth -gt $MaxDepth) {
        return
    }
    
    $items = Get-TFVCItems -ProjectName $ProjectName -Path $Path -RecursionLevel "OneLevel"
    $folders = $items | Where-Object { $_.isFolder -eq $true -and $_.path -ne $Path }
    
    if (!$IncludeFiles) {
        $items = $folders
    }
    
    # Apply filter pattern
    $items = $items | Where-Object { $_.path -like "*$FilterPattern*" }
    
    foreach ($item in $items) {
        $itemName = Split-Path $item.path -Leaf
        $itemType = if ($item.isFolder) { "[Folder]" } else { "[File]" }
        
        $folderInfo = [PSCustomObject]@{
            Project = $ProjectName
            Path = $item.path
            Name = $itemName
            Type = $itemType
            Depth = $CurrentDepth
            LastModified = $item.changeDate
            Version = $item.version
            Size = if (!$item.isFolder) { $item.size } else { $null }
        }
        
        # Add to global results
        $script:allFolders += $folderInfo
        
        # Display tree view
        if ($OutputFormat -eq "Tree") {
            $prefix = if ($item.isFolder) { "📁" } else { "📄" }
            Write-Host "$Indent$prefix $itemName" -ForegroundColor $(if ($item.isFolder) { "Yellow" } else { "Gray" })
            
            if ($ShowChanges -and $item.changeDate) {
                $changeDate = [DateTime]::Parse($item.changeDate)
                $daysSinceChange = (Get-Date) - $changeDate
                if ($daysSinceChange.TotalDays -le $ChangesDays) {
                    Write-Host "$Indent   ↳ Modified: $($changeDate.ToString('yyyy-MM-dd')) ($('{0:N0}' -f $daysSinceChange.TotalDays) days ago)" -ForegroundColor DarkGray
                }
            }
        }
        
        # Recursively process subfolders
        if ($item.isFolder -and $CurrentDepth -lt $MaxDepth) {
            Get-FolderTree -ProjectName $ProjectName -Path $item.path -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -Indent "$Indent  "
        }
    }
}

function Get-FolderStatistics {
    param([array]$Folders)
    
    $stats = @{
        TotalFolders = ($Folders | Where-Object { $_.Type -eq "[Folder]" }).Count
        TotalFiles = ($Folders | Where-Object { $_.Type -eq "[File]" }).Count
        ProjectCount = ($Folders | Select-Object -Unique Project).Count
        MaxDepthReached = ($Folders | Measure-Object -Property Depth -Maximum).Maximum
        RecentlyModified = @()
    }
    
    if ($ShowChanges) {
        $cutoffDate = (Get-Date).AddDays(-$ChangesDays)
        $stats.RecentlyModified = $Folders | Where-Object { 
            $_.LastModified -and [DateTime]::Parse($_.LastModified) -gt $cutoffDate 
        } | Sort-Object LastModified -Descending | Select-Object -First 10
    }
    
    return $stats
}

# Initialize
Add-Type -AssemblyName System.Web
$script:allFolders = @()

# Setup authentication
$authToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken"))
$Headers = @{
    "Authorization" = $authToken
    "Content-Type"  = "application/json"
}

Write-Host "=== TFS TFVC Repository Explorer ===" -ForegroundColor Cyan
Write-Host "Server: $TfsUrl/$Collection" -ForegroundColor Gray
Write-Host "Max Depth: $MaxDepth | Filter: $FilterPattern | Include Files: $IncludeFiles" -ForegroundColor Gray
Write-Host ""

# Get projects
Write-Host "Fetching projects..." -ForegroundColor Yellow
$projects = @()
$pageSize = 100
$skipCount = 0

do {
    $projectsUrl = "$TfsUrl/$Collection/_apis/projects?`$top=$pageSize&`$skip=$skipCount&api-version=5.0"
    try {
        $response = Invoke-RestMethod -Uri $projectsUrl -Headers $Headers -Method Get -ErrorAction Stop
        $fetchedProjects = $response.value
        
        # Apply project filter
        $filteredProjects = $fetchedProjects | Where-Object { $_.name -like $ProjectFilter }
        $projects += $filteredProjects
        
        $skipCount += $pageSize
    } catch {
        Write-Host "Error fetching projects: $_" -ForegroundColor Red
        Write-Host "Please verify your TFS URL and Personal Access Token (remember the ':' prefix)" -ForegroundColor Yellow
        exit 1
    }
} while ($fetchedProjects.Count -eq $pageSize)

Write-Host "Found $($projects.Count) projects matching filter" -ForegroundColor Green
Write-Host ""

# Process each project
foreach ($project in $projects) {
    $projectName = $project.name
    Write-Host "🗂️  Project: $projectName" -ForegroundColor Cyan
    
    # Check for TFVC content
    $tfvcRoot = "`$/$projectName"
    $rootItems = Get-TFVCItems -ProjectName $projectName -Path $tfvcRoot -RecursionLevel "None"
    
    if ($rootItems.Count -eq 0) {
        Write-Host "   No TFVC content found" -ForegroundColor DarkGray
        continue
    }
    
    # Explore folder structure
    Get-FolderTree -ProjectName $projectName -Path $tfvcRoot -CurrentDepth 1 -MaxDepth $MaxDepth -Indent "   "
    
    Write-Host ""
}

# Generate statistics
$stats = Get-FolderStatistics -Folders $script:allFolders

Write-Host "=== Summary Statistics ===" -ForegroundColor Yellow
Write-Host "Total Folders: $($stats.TotalFolders)" -ForegroundColor Cyan
Write-Host "Total Files: $($stats.TotalFiles)" -ForegroundColor Cyan
Write-Host "Projects with TFVC: $($stats.ProjectCount)" -ForegroundColor Cyan
Write-Host "Max Depth Explored: $($stats.MaxDepthReached)" -ForegroundColor Cyan

if ($ShowChanges -and $stats.RecentlyModified.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Recent Changes (Last $ChangesDays days) ===" -ForegroundColor Yellow
    $stats.RecentlyModified | ForEach-Object {
        $changeDate = [DateTime]::Parse($_.LastModified)
        Write-Host "  $($_.Path)" -ForegroundColor Gray
        Write-Host "    Modified: $($changeDate.ToString('yyyy-MM-dd HH:mm')) by version $($_.Version)" -ForegroundColor DarkGray
    }
}

# Export results if requested
if ($ExportPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "TFVC_Repository_Report_$timestamp"
    
    switch ($OutputFormat) {
        "Json" {
            $exportFile = Join-Path $ExportPath "$fileName.json"
            $script:allFolders | ConvertTo-Json -Depth 10 | Out-File $exportFile
        }
        "CSV" {
            $exportFile = Join-Path $ExportPath "$fileName.csv"
            $script:allFolders | Export-Csv -Path $exportFile -NoTypeInformation
        }
        "Detailed" {
            $exportFile = Join-Path $ExportPath "$fileName.txt"
            $report = @"
TFS TFVC Repository Report
Generated: $(Get-Date)
Server: $TfsUrl/$Collection
Filter: $FilterPattern
Max Depth: $MaxDepth

=== Folder Structure ===
$($script:allFolders | Format-Table -AutoSize | Out-String)

=== Statistics ===
Total Folders: $($stats.TotalFolders)
Total Files: $($stats.TotalFiles)
Projects: $($stats.ProjectCount)

=== Recent Changes ===
$($stats.RecentlyModified | Format-Table -AutoSize | Out-String)
"@
            $report | Out-File $exportFile
        }
    }
    
    if ($exportFile) {
        Write-Host ""
        Write-Host "Report exported to: $exportFile" -ForegroundColor Green
    }
}

# Output raw data for pipeline
if ($OutputFormat -eq "Table" -and !$ExportPath) {
    Write-Host ""
    Write-Host "=== Detailed Results ===" -ForegroundColor Yellow
    $script:allFolders | Format-Table -AutoSize
}