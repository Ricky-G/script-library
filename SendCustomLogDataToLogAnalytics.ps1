##### >>>> PUT YOUR VALUES HERE <<<<<
$tenantId = "<insert your tenant id here>";
$appId = "<insert your app id here>";
$appSecret = "<insert your app secret here>";

$DcrImmutableId = "<insert your DCR immutable id here>";

$DceURI = "<insert your DCE URI here>";
$Table = "<insert your table name here>";
##### >>>> END <<<<<

# Function to obtain a bearer token used to authenticate against the data collection endpoint
function Get-BearerToken {
    Write-Host "Getting the Bearer Token..."
    
    # Use Uri.EscapeDataString for URL encoding
    $scope = [Uri]::EscapeDataString("https://monitor.azure.com//.default")
    $body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials"
    $headers = @{"Content-Type" = "application/x-www-form-urlencoded" }
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    
    $token = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
    
    if ($token) {
        Write-Host "Bearer Token obtained successfully."
        return $token
    }
    else {
        Write-Host "Failed to obtain the Bearer Token."
        return $null
    }
}

# Sending predefined data to Log Analytics via the DCR
function Send-LogToAzure {
    Write-Host "Initiating process to send log to Azure..."
    
    $bearerToken = (Get-BearerToken).Trim()

    if (-not $bearerToken) {
        Write-Host "Aborting due to absence of Bearer Token."
        return
    }

    # Define the sample log entries within an array
    $log_entry_array = @(
        @{
            TimeGenerated = "2023-10-19 21:00:15"
            FileName      = "SampleFile1.txt"
            Outcome       = "Success"
            LogicAppName  = "LogicApp#2"
        },
        @{
            TimeGenerated = "2023-10-19 21:00:15"
            FileName      = "SampleFile2.txt"
            Outcome       = "Failure"
            LogicAppName  = "LogicApp#2"
        }
    )
    
    # Convert the array to JSON
    $body = $log_entry_array | ConvertTo-Json
    
    # Print the JSON representation to console
    Write-Output "Body Content:"
    Write-Output $body    

    Write-Host "Setting headers and making the API request..."    
    $headers = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json" };
    $uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table" + "?api-version=2021-11-01-preview"

    Write-Host $uri
    Write-Host $headers
    
    try {
        $uploadResponse = Invoke-WebRequest -Uri $uri -Method "Post" -Body $body -Headers $headers
    
        $statusCode = $uploadResponse.StatusCode
        $content = $uploadResponse.Content | ConvertFrom-Json
    
        Write-Output "Response from Azure:"
        Write-Output "Status Code: $statusCode"
        if ($content) {
            Write-Output $content
        }
    }
    catch {
        Write-Output "Error encountered while sending data to Azure:"
        Write-Output $_.Exception.Message
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $streamReader = [System.IO.StreamReader]::new($responseStream)
            $responseBody = $streamReader.ReadToEnd()
            Write-Output "Detailed error from Azure:"
            Write-Output $responseBody
        }
    }    
}

# Execute the function to send the log
Send-LogToAzure
