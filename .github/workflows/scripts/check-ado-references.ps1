$patterns = @("https://dev.azure.com/", "AB#")
$found = $false

# Fetch the PR number from the GitHub event
$prNumber = (Get-Content $env:GITHUB_EVENT_PATH | ConvertFrom-Json).number

# Fetch the PR details using GitHub REST API
$prDetails = Invoke-RestMethod -Uri "https://api.github.com/repos/$env:GITHUB_REPOSITORY/pulls/$prNumber" -Headers @{ Authorization = "token $env:GITHUB_TOKEN" }

# Check the PR title
foreach ($pattern in $patterns) {
    if ($prDetails.title -match $pattern) {
        Write-Output "Error: ADO work item references found in PR title."
        $found = $true
    }
}

# Check the PR description 
foreach ($pattern in $patterns) {
    if ($prDetails.body -match $pattern) {
        Write-Output "Error: ADO work item references found in PR description."
        $found = $true
    }
}

# Fetch the PR comments using GitHub REST API
$prComments = Invoke-RestMethod -Uri "https://api.github.com/repos/$env:GITHUB_REPOSITORY/issues/$prNumber/comments" -Headers @{ Authorization = "token $env:GITHUB_TOKEN" }

# Check the PR comments 
foreach ($comment in $prComments) {
    foreach ($pattern in $patterns) {
        if ($comment.body -match $pattern) {
            Write-Output "Error: ADO work item references found in PR comments."
            $found = $true
        }
    }
}

# Exit with an error code if any references are found
if ($found) {
    Write-Output "Error: References to ADO work items found."
    exit 1
}
else {
    Write-Output "No references to ADO work items found."
}