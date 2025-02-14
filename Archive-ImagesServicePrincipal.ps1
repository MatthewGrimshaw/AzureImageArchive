param(
    $SharedFolder,
    $StorageAccoutName,
    $container,
    $azcopyAppID,
    $AZCOPY_SPA_CLIENT_SECRET
)

    <#
    .SYNOPSIS
        Uploads Images to Azure Storage using AzCopy.
    .EXAMPLE
        powershell -ExecutionPolicy Bypass -File .\Archive-ImagesServicePrincipal.ps1 -SharedFolder "\\ImageStore\Images" -StorageAccoutName "https://<storageaccountname>.blob.core.windows.net/<blobcontainer>" -container "<root folder on the file share to connect to>" -azcopyAppID "appID of the Service Principal" -AZCOPY_SPA_CLIENT_SECRET "Service Principal Client Secret" -tenantid 'tenant id'
    #>

function Write-ToEventLog{
    param($message)
    eventcreate /t error /id 99 /l application /d $message
}

# configure proxy credentials
try{
    $browser = New-Object System.Net.WebClient
    $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials
}
catch{
    Write-ToEventLog $Error[0].Exception.GetType().FullName
    write-error $Error[0].Exception.GetType().FullName
    Stop-Transcript
    exit
}

# set user variables
$month = Get-Date -format MMMM
$Date = Get-Date -Format "yyyyMMdd"
$Date = $Date.Replace('/','-')
$uri = "$($StorageAccoutName)/$($container)/$($month)/$Date/$($fileToUpload)"

Start-Transcript -Path ".\ArchiveImages-$Date.log"

# az copy arguments
$azCopyArgsoverwrite = '--overwrite=ifSourceNewer'
$azCopyArgsfromto  = '--from-to=LocalBlob' 
$azCopyArgsfollowsymlinks = '--follow-symlinks'
$azCopyArgsputmd5 = '--put-md5'

# sign into Azure using the Service Princpal
& "./AzCopy/*/azcopy.exe" login --service-principal --application-id $azcopyAppID --tenant-id $tenantid


###################### download AzCopy ######################
#
# uncomment to use
#
#Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip -UseBasicParsing
#Expand-Archive ./AzCopy.zip ./AzCopy -Force
#############################################################

# write to Event Log if AzCopy is not found
if ( -Not (Test-Path -Path "./AzCopy/*/azcopy.exe" ) ) { 
    Write-ToEventLog "AzCopy has not been downloaded. Script will not continue. Please download AzCopy and run the script again"
    write-error "Az Copy not found"
    stop-transcript
    exit
}


If( -Not (Test-Path "$($SharedFolder)\$($container)\$($Date)\")){
    $errorMessage = "Folder $($SharedFolder)\$($container)\$($Date)\ not found - script will exit"
    Write-ToEventLog $errorMessage
    write-error $errorMessage
    Stop-Transcript
    exit
}

# Upload Files
$filesToUpload = Get-ChildItem "$($SharedFolder)\$($container)\$($Date)\"


foreach($fileToUpload in $filesToUpload){
  write-output "$fileToUpload will be archived to Azure"
  $copyJob = ./AzCopy/*/azcopy.exe copy $fileToUpload.FullName $uri $azCopyArgsoverwrite $azCopyArgsfromto $azCopyArgsfollowsymlinks $azCopyArgsputmd5
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

Stop-Transcript

