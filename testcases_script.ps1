function generate_test_files {
    param (
        [string]$path,
        [int]$fileCount,
        [int]$fileSizeMB
    )

    if (-not $path) {
        Write-Host "The path for generating files cannot be empty."
        exit 1
    }

    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
    }

    Write-Host " Generating $fileCount files to $fileSizeMB MB in directory $path..."
    for ($i = 1; $i -le $fileCount; $i++) {
        $fileName = Join-Path $path "test_file_$i.dat"
        fsutil file createnew $fileName ($fileSizeMB * 1MB) | Out-Null
    }
}

function run_test {
    param (
        [string]$sourcePath,
        [string]$archivePath,
        [int]$diskUsageThreshold,
        [int]$fileCount,
        [int64]$maxSize,
        [string]$testName
    )

    if (-not $sourcePath) {
        Write-Host "sourcePath cannot be empty"
        exit 1
    }

    if (-not $archivePath) {
        Write-Host "archivePath cannot be empty"
        exit 1
    }

    Write-Host "`nTest: $testName"
    Write-Host "------------------------------------"
    
    & .\test_0.ps1 -sourcePath $sourcePath -archivePath $archivePath -diskUsageThreshold $diskUsageThreshold -fileCount $fileCount -maxSize $maxSize

    $archiveName = Join-Path $archivePath "archive.zip"
    if (Test-Path $archiveName) {
        Write-Host "The $testName test was successful: The $archiveName archive was created."
    } else {
        Write-Host "The $testName test failed: The $archiveName archive was not created."
    }

    Write-Host "------------------------------------"
}

$logDir = "$HOME/log"
$backupDir = "$HOME/backup"

generate_test_files -path $logDir -fileCount 20 -fileSizeMB 25

run_test -sourcePath $logDir -archivePath $backupDir -diskUsageThreshold 50 -fileCount 10 -maxSize 1GB -testName "Test1"
run_test -sourcePath $logDir -archivePath $backupDir -diskUsageThreshold 30 -fileCount 15 -maxSize 1GB -testName "Test2"
run_test -sourcePath $logDir -archivePath $backupDir -diskUsageThreshold 80 -fileCount 10 -maxSize 1GB -testName "Test3"
run_test -sourcePath $logDir -archivePath $backupDir -diskUsageThreshold 50 -fileCount 20 -maxSize 2GB -testName "Test4"
