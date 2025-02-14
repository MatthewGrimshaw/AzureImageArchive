$rootShare = "\\ImageStore\Images"
$ImagePrefix = "<prefix to append to the image archive file name>"
$storageAccoutName = "https://<storageaccountname>.blob.core.windows.net/<blobcontainername>"
$sasKey = "<saskeyvalue>"


for ($i = 1; $i -le 20; $i++) {
    Write-Host "Iteration number: $i"

    if ( -Not (Test-Path -Path "$rootShare\QCZ0$i" ) ) { 
        New-Item -Path "$rootShare" -Name "QCZ0$i" -ItemType Directory
    }

    $Date = Get-Date -Format "yyyyMMdd"
    $DateHourMinuteSeconds = Get-Date -Format "HHmmss"
    $DateMilliSeconds = Get-Date -Format "ffffff"

    if ( -Not (Test-Path -Path "\$rootShare\QCZ0$i\$Date" ) ) {
        New-Item -Path "$rootShare\QCZ0$i" -Name $Date -ItemType Directory
    }

    
    $compress = @{
        Path = "C:\ImageUpload\images\*.bmp"
        CompressionLevel = "Fastest"
        DestinationPath = "$rootShare\QCZ0$i\$Date\$ImagePrefix-$Date-$DateHourMinuteSeconds-$DateMilliSeconds.zip"
      }
      Compress-Archive @compress
  }

  for ($i = 1; $i -le 20; $i++) {
  powershell -ExecutionPolicy Bypass -File .\Archive-Images.ps1 -SharedFolder "$rootShare" -StorageAccoutName "$storageAccoutName" -container "QCZ0$i" -saskey "$sasKey"
}