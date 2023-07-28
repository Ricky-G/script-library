<#
    7ZipArchiveCracker.ps1

    Please make sure you have 7-Zip installed on your machine and the path to the executable is correct.

    This PowerShell script attempts to extract a password-protected 7-Zip archive using a list of passwords provided in a text file. 
    The script requires 7-Zip to be installed on the machine and the path to the executable to be correct.

    The script reads the list of passwords from a file and then tries each password until the archive is successfully extracted or all passwords have been tried. 
    The script prints the password that is currently being tried and whether the archive was extracted successfully or not.

    To use this script, the user must replace the paths to the archive, passwords file, and output directory with their own paths. 
    The user must also make sure that 7-Zip is installed on their machine and the path to the executable is correct.
#>

# Define the paths to your files
$archive = "C:\temp\Test.7z"
$passwordsFile = "C:\temp\pds.txt"
$outputDirectory = "C:\temp\output"

# Read the passwords from the file
$passwords = Get-Content -Path $passwordsFile

# Try each password
foreach ($password in $passwords)
{
    # Print the password that is currently being tried
    Write-Output "Trying password: '$password'"

    # Try to extract the archive with the current password
    $output = & 'C:\Program Files\7-Zip\7z.exe' x "-p$password" -y $archive "-o$outputDirectory" 2>&1

    # Check if the operation succeeded
    if ($LASTEXITCODE -eq 0)
    {
        Write-Output "Archive extracted successfully! Password: $password"
        break
    }
}
