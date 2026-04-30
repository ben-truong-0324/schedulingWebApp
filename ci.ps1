param (
    [switch]$DoPush
)

$ErrorActionPreference = "Stop"
$ImageName = "grooming-app-test"
$ContainerName = "grooming-webapp-local"


if (Test-Path ".env") {
    Get-Content .env | Foreach-Object {
        if ($_ -match "^(?<name>[^=]+)=(?<value>.*)$") {
            $name = $Matches['name'].Trim()
            $value = $Matches['value'].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
}

function Check-LastCommand {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nERROR: The previous command failed with exit code $LASTEXITCODE. Aborting." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "--- 1. Cleaning & Building (.NET) ---" -ForegroundColor Cyan
dotnet build Src/schedulingWebApp.slnx --configuration Release; Check-LastCommand

Write-Host "--- 2. Running Unit Tests ---" -ForegroundColor Cyan
dotnet test Src/schedulingWebApp.slnx --no-build --configuration Release; Check-LastCommand

Write-Host "--- 3. Docker Cleanup & Build ---" -ForegroundColor Cyan
# 1. Kill the container first (releases the image)
docker stop $ContainerName 2>$null
docker rm $ContainerName 2>$null

# 2. Delete the old image
Write-Host "Removing old image: $ImageName" -DarkGray
docker rmi $ImageName 2>$null

# 3. Build the fresh image
docker build -t $ImageName .; Check-LastCommand

Write-Host "--- 4. Starting Local Container ---" -ForegroundColor Cyan
$KeyPath = Resolve-Path ".\gcp-key.json"

docker run -d `
    --name $ContainerName `
    -p 9090:8080 `
    -e PORT=8080 `
    -e ASPNETCORE_ENVIRONMENT=$env:ASPNETCORE_ENVIRONMENT `
    -e GOOGLE_CLOUD_PROJECT=$env:GOOGLE_CLOUD_PROJECT `
    -e FIRESTORE_DATABASE_ID=$env:FIRESTORE_DATABASE_ID `
    -e GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-key.json `
    -v "${KeyPath}:/app/gcp-key.json" `
    $ImageName; Check-LastCommand

Write-Host "`nSUCCESS: App is running locally at http://localhost:9090" -ForegroundColor Green

if ($DoPush) {
    Write-Host "`n--- 5. Pushing to GitHub ---" -ForegroundColor Magenta
    if (git status --porcelain) {
        git add .
        git commit -m "updated"; Check-LastCommand
        git push; Check-LastCommand
        Write-Host "GitHub Push Complete!" -ForegroundColor Green
    } else {
        Write-Host "No changes detected. Skipping commit/push." -ForegroundColor Yellow
    }
}

Write-Host "Cleaning up dangling build layers..." -DarkGray
docker image prune -f