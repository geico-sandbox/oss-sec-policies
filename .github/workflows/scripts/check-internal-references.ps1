# internal artifactory patterns
$patterns = @("packageregistry-np.geico.net", "packageregistry.geico.net", "artifactory-pd-infra.aks.aze1.cloud.geico.net")
$found = $false

# Get the path of the current script
$currentScript = $MyInvocation.MyCommand.Path


# Loop through each pattern and search the codebase
foreach ($pattern in $patterns) {
    $results = Get-ChildItem -Recurse -File | Where-Object { $_.FullName -ne $currentScript } | Select-String -Pattern $pattern
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