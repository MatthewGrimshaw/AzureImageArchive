param(
  $serverShare # \\ImageStore\Images
)

# powershell -ExecutionPolicy Bypass -File .\create-folderstructure.ps1 -serverShare \\ImageStore\Images

for ($i = 1; $i -le 20; $i++) {
    Write-Host "Iteration number: $i"

    if ( -Not (Test-Path -Path "$serverShare\QCZ0$i" ) ) { 
        New-Item -Path "$serverShare" -Name "QCZ0$i" -ItemType Directory
    }

    $Date = (Get-Date).AddDays(-1).ToString("yyyyMMdd")
    
    $DateHourMinuteSeconds = Get-Date -Format "HHmmss"
    $DateMilliSeconds = Get-Date -Format "ffffff"

    if ( -Not (Test-Path -Path "$serverShare\QCZ0$i\$Date" ) ) {
        New-Item -Path "$serverShare\QCZ0$i" -Name $Date -ItemType Directory
    }

    $ImagePrefix = "APMT-TM2-Tangier"
    $compress = @{
        Path = "C:\ImageUpload\images\*.bmp"
        CompressionLevel = "Fastest"
        DestinationPath = "$serverShare\QCZ0$i\$Date\$ImagePrefix-$Date-$DateHourMinuteSeconds-$DateMilliSeconds.zip"
      }
      Compress-Archive @compress
  }

for ($i = 1; $i -le 20; $i++) {
  powershell -ExecutionPolicy Bypass -File .\Archive-Images.ps1 -SharedFolder $serverShare -StorageAccoutName "https://imageuploadlkjokcm.blob.core.windows.net/tangierprodarchive" -container "QCZ0$i" -saskey $env:AZURE_IMAGE_ARCHIVE_SASKEY
}