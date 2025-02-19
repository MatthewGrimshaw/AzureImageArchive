# AzureImageArchive
Example scripts to upload images to an Azure storage account

## Description

These scripts provide an example of how to upload compressed images (.zip files) to an Azure Storage Account.

- They will connect to a Share folder on a File Server and check for image archives that have been created on the same day and upload them to Azure Storage.
- They will preserve the file path and fil names on the Azure Storage.
- They are designed to be run via a Windows Scheduled Task on a predefined schedule (for example, once a day or every 15 minutes).
- They can be scheduled to run in parallel for each root folder on the file share.
- They use the AzCopy utility to upload files to Azure Storage.
- They create a local log file and write to the Windows Event Log in the case of Errors for debugging purposes. 
- Windows Monitoring tools can pick up events form the Windows Event Log and raise alerts in the case of failure.
- The script will create erros and warnings in the Windows Event Log when the SAS Token is close to expiration
- The Script has a function to delete log files that are older than 30 days

## Archive-Image.ps1

- This script uses a SAS Key to connect to the Storage Account.
- The SAS key will need to updated when it expires.
- 

## Archive-ImageServicePrincipal.ps1

- This script uses an EntraID Service Principal to connect to the Storage Account.
- The EntraID Service principal client secret will need to be stored securely
- Windows Credential Manager can be used to store client secrets, but the script needs to be provide this integration
- Note, this script needs to be updated to read the Service Principal sedcret from an environment variable
- 

## Scheduled Task

To create a schedule task to execture thes scripts on a schedule use the following:

Program / Script: Powershell

Add Arguments: -ExecutionPolicy Bypass -File .\Archive-Images.ps1 -SharedFolder "\\Server\Share" -StorageAccoutName "https://<storageaccountname>.blob.core.windows.net/<blobcontainer>" container "<root folder on the file share to connect to>" -saskey "saskeyvalue"

## Testing

Use Create-TestFiles.ps1 to test this script in a test environment

powershell -ExecutionPolicy Bypass -File .\create-folderstructure.ps1 -serverShare \\ImageStore\Images

## Updating SAS TOKEN

Use the write-emvironmentvariables.ps1 script to update with a new sas token

powershell -ExecutionPolicy Bypass -File .\write-environmentvariable.ps1 -saskey "saskeyvalue"