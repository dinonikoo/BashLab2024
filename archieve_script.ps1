param (
    [string]$sourcePath,
    [string]$archivePath,
    [int]$diskUsageThreshold,
    [int]$fileCount,
    [int64]$maxSize
)

# Валидация параметров
if (-not $sourcePath) {
    Write-Host "Specify the path to the files to archive."
    exit 1
}
if (-not $archivePath) {
    Write-Host "Specify the path to create the archive."
    exit 1
}
if (-not $diskUsageThreshold) {
    Write-Host "Specify the disk usage percentage threshold."
    exit 1
}
if (-not $fileCount) {
    Write-Host "Specify the number of files to archive."
    exit 1
}
if (-not $maxSize) {
    Write-Host "Specify the max size."
    exit 1
}

# Получаем размер папки
$usedSpace = (Get-ChildItem -Path $sourcePath -Recurse | Measure-Object -Property Length -Sum).Sum
$usedPercentage = [math]::Round(($usedSpace / $maxSize) * 100)

# Проверяем, превышает ли использование диска порог
if ($usedPercentage -lt $diskUsageThreshold) {
    Write-Host "Disk usage is $usedPercentage%, below the threshold $diskUsageThreshold% - archiving will not start."
    exit 0
}

# Архивирование файлов
$archiveName = Join-Path $archivePath "archive.zip"

# Если архив уже существует, удаляем его
if (Test-Path $archiveName) {
    Remove-Item $archiveName -Force
}

# Получаем список файлов в исходной папке
$fileList = Get-ChildItem -Path $sourcePath | Sort-Object LastWriteTime | Select-Object -First $fileCount

# Проверяем количество файлов для архивирования
if ($fileList.Count -lt $fileCount) {
    Write-Host "Not enough files to archive. Found $($fileList.Count) files, but need $fileCount."
    exit 0
}

Write-Host "Archiving the oldest $fileCount files from '$sourcePath' to '$archiveName'..."

# Архивируем файлы
Compress-Archive -Path $fileList.FullName -DestinationPath $archiveName -CompressionLevel Optimal -Force

Write-Host "Deleting the oldest $fileCount files..."

# Удаление архивированных файлов
$fileList | ForEach-Object { Remove-Item $_.FullName -Force }

Write-Host "Deleted $fileCount files."
