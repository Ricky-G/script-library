# TFS TFVC Repository Scripts

## Overview

This collection of PowerShell scripts provides comprehensive tools for exploring and managing Team Foundation Version Control (TFVC) repositories in TFS/Azure DevOps Server. Unlike Git's repository-based model, TFVC uses a hierarchical folder structure where "repositories" are typically represented as top-level folders under each project's root path (`$/ProjectName`).

## Why These Scripts?

Working with TFVC through the REST API presents unique challenges:
- No direct "list repositories" endpoint like Git
- The API requires understanding TFVC's folder-based hierarchy
- Discovering all repositories requires traversing folder structures
- Different organizations structure their TFVC folders differently
- Need for flexible filtering and reporting options

These scripts address these challenges by providing purpose-built tools for different TFVC exploration needs.

## Scripts Included

### 1. TFS-TFVCTopLevelFolders.ps1 (🚀 Quick Start)
**Purpose**: The simplest way to get a complete list of all TFVC top-level folders across your TFS instance.

**Key Features**:
- ✅ Zero parameters required - just configure and run
- 📊 Interactive export options (CSV, JSON, HTML reports)
- 🔄 Progress tracking for large TFS instances
- 📁 Shows all TFVC "repositories" (top-level folders)
- ⚡ Optimized for performance with pagination support

**Best For**: Quick discovery of all TFVC repositories, generating management reports, initial TFVC exploration

**Usage**:
```powershell
# Update the script with your TFS URL and PAT, then run:
.\TFS-TFVCTopLevelFolders.ps1
```

### 2. TFS-TFVCRepositoryLister.ps1 (⚙️ Configurable)
**Purpose**: Flexible script with command-line parameters for customized TFVC folder discovery.

**Key Features**:
- 🎛️ Configurable recursion levels (None, OneLevel, Full)
- 📈 Optional item count statistics per folder
- 🗂️ Multiple output formats (Table, JSON, CSV)
- 🔍 Include/exclude empty folders
- 📊 Repository statistics and project summaries

**Best For**: Automated reporting, CI/CD integration, customized folder analysis

**Usage**:
```powershell
# Basic usage with default settings
.\TFS-TFVCRepositoryLister.ps1

# Show item counts and export to CSV
.\TFS-TFVCRepositoryLister.ps1 -RecursionLevel "OneLevel" -ShowItemCount -OutputFormat "CSV"

# Include empty folders in the results
.\TFS-TFVCRepositoryLister.ps1 -IncludeEmptyFolders -OutputFormat "Json"
```

### 3. TFS-TFVCRepositoryExplorer.ps1 (🔍 Advanced Explorer)
**Purpose**: Power-user tool for deep TFVC structure analysis with advanced filtering and visualization.

**Key Features**:
- 🌳 Beautiful tree view visualization of folder hierarchy
- 🔄 Configurable traversal depth (prevent overwhelming output)
- 🎯 Pattern-based filtering (wildcards supported)
- 📅 Change history tracking with date filtering
- 📁 Optional file inclusion (not just folders)
- 📊 Comprehensive statistics and recent change reports
- 🚀 Performance optimizations for large repositories

**Best For**: Deep repository analysis, finding specific folders, change tracking, visual hierarchy exploration

**Usage**:
```powershell
# Visual tree view of folder structure (2 levels deep)
.\TFS-TFVCRepositoryExplorer.ps1 -MaxDepth 2 -OutputFormat Tree

# Find all "Main" branches with recent changes
.\TFS-TFVCRepositoryExplorer.ps1 -FilterPattern "*Main*" -ShowChanges -ChangesDays 30

# Deep scan with detailed report export
.\TFS-TFVCRepositoryExplorer.ps1 -MaxDepth 3 -ExportPath "C:\Reports" -OutputFormat Detailed

# Include files and filter by project
.\TFS-TFVCRepositoryExplorer.ps1 -ProjectFilter "MyProject*" -IncludeFiles -MaxDepth 2
```

## Configuration

All scripts require:

1. **TFS Server URL**: Update the `$tfsUrl` variable with your TFS server address
2. **Collection Name**: Update the `$collection` variable (usually "DefaultCollection")
3. **Personal Access Token (PAT)**: 
   - Create a PAT with TFVC read permissions
   - Update the `$accessToken` variable
   - **Important**: Keep the colon (`:`) prefix before your PAT

Example:
```powershell
$tfsUrl = "http://your-tfs-server:8080/tfs"
$collection = "DefaultCollection"
$accessToken = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":your-pat-token-here"))
```

## Understanding TFVC Structure

In TFVC, the folder hierarchy typically looks like:
```
$/                          # Root
├── ProjectA/              # Project root
│   ├── Main/             # Repository/Branch
│   ├── Development/      # Repository/Branch
│   └── Releases/         # Repository/Branch
├── ProjectB/
│   ├── Trunk/
│   └── Features/
```

These scripts help you discover and list these top-level folders that serve as "repositories" in TFVC.

## API Details

The scripts use the TFVC Items REST API:
- **Endpoint**: `GET {tfsUrl}/{collection}/{project}/_apis/tfvc/items`
- **Key Parameters**:
  - `scopePath`: The folder path to query (e.g., `$/ProjectName`)
  - `recursionLevel`: 
    - `None`: Just the specified item
    - `OneLevel`: Item and direct children
    - `Full`: Item and all descendants

## Troubleshooting

### Common Issues:

1. **Authentication Errors**
   - Verify your PAT has TFVC read permissions
   - Ensure the colon (`:`) prefix is included before the PAT
   - Check if the PAT is still valid (not expired)

2. **No Results Returned**
   - Verify the project uses TFVC (not Git)
   - Check if you have permissions to view the TFVC content
   - Try accessing a specific project directly

3. **API Errors**
   - Ensure your TFS version supports the REST API (TFS 2015+)
   - Verify the API version in the URL (e.g., `api-version=5.0`)
   - Check network connectivity to the TFS server

### Debug Mode

Add `-Verbose` parameter to see detailed API calls:
```powershell
.\TFS-TFVCRepositoryExplorer.ps1 -Verbose
```

## Performance Considerations

- **Large TFS Instances**: Scripts include pagination and progress tracking
- **Recursion Levels**: 
  - `None`: Fastest - just the root items
  - `OneLevel`: Balanced - immediate children only
  - `Full`: Slowest - entire tree (use with caution)
- **Optimization Tips**:
  - Filter by specific projects to reduce API calls
  - Use `-MaxDepth` parameter to limit traversal
  - Export results for offline analysis
  - Run during off-peak hours for better performance

## Export Formats

All scripts support multiple export formats:
- **CSV**: For Excel analysis
- **JSON**: For programmatic processing
- **HTML**: For formatted reports
- **Tree**: For visual hierarchy representation

## Requirements

- **PowerShell**: Version 3.0 or later
- **TFS/Azure DevOps**: TFS 2015 or later / Azure DevOps Server
- **Authentication**: Personal Access Token (PAT) with TFVC read permissions
- **Network**: Direct access to TFS server (proxy configuration may be needed)
- **Memory**: Sufficient RAM for large result sets (especially with Full recursion)

## Quick Decision Guide

| Need | Recommended Script |
|------|-------------------|
| List all TFVC repositories quickly | TFS-TFVCTopLevelFolders.ps1 |
| Generate automated reports | TFS-TFVCRepositoryLister.ps1 |
| Explore folder structure visually | TFS-TFVCRepositoryExplorer.ps1 |
| Find specific folders by pattern | TFS-TFVCRepositoryExplorer.ps1 |
| Track recent changes | TFS-TFVCRepositoryExplorer.ps1 |
| Count items in folders | TFS-TFVCRepositoryLister.ps1 |

## Security Notes

- Store PATs securely (consider using Secret Management module)
- Scripts use HTTPS/TLS for API communication
- No credentials are logged or exported
- PATs should have minimal required permissions (TFVC read-only)

## Contributing

Improvements and bug fixes are welcome! Please ensure:
- PATs and server URLs remain as placeholders
- Error handling is maintained
- Performance optimizations are tested with large datasets