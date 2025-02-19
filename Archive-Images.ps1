param(
    $SharedFolder,
    $StorageAccoutName,
    $container
)

    <#
    .SYNOPSIS
        Uploads Images to Azure Storage using AzCopy.
    .EXAMPLE
        powershell -ExecutionPolicy Bypass -File .\Archive-Images.ps1 -SharedFolder "\\ImageStore\Images" -StorageAccoutName "https://imageuploadlkjokcm.blob.core.windows.net/tangierprodarchive" -container "QCZ01"
    #>

    function Write-ToEventLog{
        param(
            $message,
            $errorlevel
            )
            
        switch(($errorlevel).ToLower())
        {
            "error" {eventcreate /t error /id 99 /l application /d $message}
            "warning" {eventcreate /t warning /id 98 /l application /d $message}
            "information" {eventcreate /t information /id 97 /l application /d $message}
        }
    }

# configure proxy credentials
try{
    # uncomment if the proxy requires authenticaiton
    #$browser = New-Object System.Net.WebClient
    #$browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials
    #[System.Net.Http.HttpClient]::DefaultProxy = New-Object System.Net.WebProxy('http://your-proxy:1234')
}
catch{
    Write-ToEventLog -message $Error[0].Exception.GetType().FullName -errorlevel "error"
    write-error $Error[0].Exception.GetType().FullName
    Write-ToEventLog -message "Unable to set Proxy settings" -errorlevel "error"
    write-error "Unable to set Proxy settings"
    exit
}

# set user variables
$month = Get-Date -format MMMM
$Date = (Get-Date).AddDays(-1).ToString("yyyyMMdd")
$DateMilliSeconds = Get-Date -Format "ffffff"
$uri = "$($StorageAccoutName)/$($container)/$($month)/$Date/$($fileToUpload)?$($env:AZURE_IMAGE_ARCHIVE_SASKEY)"


# az copy arguments
$azCopyArgsoverwrite = '--overwrite=ifSourceNewer'
$azCopyArgsfromto  = '--from-to=LocalBlob' 
$azCopyArgsfollowsymlinks = '--follow-symlinks'
$azCopyArgsputmd5 = '--put-md5'
#$azCopyArgscapmbs = '--cap-mbps 10' - not working, needs investigation

Start-Transcript -Path ".\Logs\ArchiveImages-$container-$Date-$DateMilliSeconds.log"

###################### download AzCopy ######################
#
# uncomment to use
#
#Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip -UseBasicParsing
#Expand-Archive ./AzCopy.zip ./AzCopy -Force
#
#############################################################

# write to Event Log if AzCopy is not found
if ( -Not (Test-Path -Path "./AzCopy/*/azcopy.exe" ) ) { 
    Write-ToEventLog -Message "AzCopy has not been downloaded. Script will not continue. Please download AzCopy and run the script again" -errorlevel "error"
    write-error "Az Copy not found"
    stop-transcript
    exit
}

If( -Not (Test-Path "$($SharedFolder)\$($container)\$($Date)\")){
    $errorMessage = "Folder $($SharedFolder)\$($container)\$($Date)\ not found - nothing to do - script will exit" 
    Write-ToEventLog -message $errorMessage -errorlevel "information"
    write-error $errorMessage
    Stop-Transcript
    exit
}


# Upload Files
$filesToUpload = Get-ChildItem "$($SharedFolder)\$($container)\$($Date)\"

foreach($fileToUpload in $filesToUpload){
  write-output "$fileToUpload will be archived to Azure"
  $copyJob = ./AzCopy/*/azcopy.exe copy $fileToUpload.FullName $uri $azCopyArgsoverwrite $azCopyArgsfromto $azCopyArgsfollowsymlinks #$azCopyArgsputmd5
  switch ($copyJob) {
    {$_.Contains("Number of File Transfers Failed: 1")}{Write-ToEventLog "File $($fileToUpload.FullName) failed to upload"}
    {$_.Contains("Number of Folder Transfers Failed: 1")}{Write-ToEventLog "Folder failed to upload"}
    {$_.Contains("Number of Folder Transfers Failed: 1")}{Write-ToEventLog "File $($fileToUpload.FullName) upload was skipped"}
    {$_.Contains("Number of Folder Transfers Failed: 1")}{Write-ToEventLog "Folder failed to upload"}
    {$_.Contains("Number of Folder Transfers Skipped: 1")}{Write-ToEventLog "Folder Transfers Skipped"}
    {$_.Contains("Final Job Status:Failed")}{Write-ToEventLog "Final Job Status:Failed"}
  }
  write-output $copyJob
}

# clean up log files
if(-Not(Test-Path -Path ".\Logs")){
    $errorMessage = "Directory .\Logs not found - cant´t clean up log files - script will exit" 
    Write-ToEventLog -message $errorMessage -errorlevel "error"
    write-error $errorMessage
    Stop-Transcript
    exit
}


$logs = Get-ChildItem -Path ".\Logs"

foreach($log in $logs){
    try{
        if($log.CreationTime -lt (Get-Date).AddDays(-1)){
            Remove-Item -Path $log.FullName
        }
        
    }
    catch{
        Write-ToEventLog -message $Error[0].Exception.GetType().FullName -errorlevel "error"
        write-error $Error[0].Exception.GetType().FullName
        Write-ToEventLog -message "Unable to delete Log File $($Log.Name)" -errorlevel "error"
        write-error "Unable to delete Log File $($Log.Name)"
        Stop-Transcript
        exit
    }
}


Stop-Transcript

