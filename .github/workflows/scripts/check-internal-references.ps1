# Define the patterns to search for
$patterns = @("packageregistry-np.geico.net", "packageregistry.geico.net", "artifactory-pd-infra.aks.aze1.cloud.geico.net")

# Initialize a flag to track if any references are found
$found = $false

# Loop through each pattern and search the codebase
foreach ($pattern in $patterns) {
    $results = Get-ChildItem -Recurse -File | Select-String -Pattern $pattern
    if ($results) {
        Write-Output "Found reference to internal package management system: $pattern"
        $found = $true
    }
}

# Exit with an error code if any references are found
if ($found) {
    Write-Output "Error: References to internal package management system found."
    exit 1
}
else {
    Write-Output "No references to internal package management system found."
}