param(
    $saskey
)


#powershell -ExecutionPolicy Bypass -File .\write-environmentvariable.ps1 -saskey "saskeyvalue"
#Requires -RunAsAdministrator

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

# check if script is running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
    write-warning "Please run this script with Administrator permissions"
    Write-ToEventLog -message "Please run this script with Administrator permissions" -errorlevel "warning"
}


If(($env:AZURE_IMAGE_ARCHIVE_SASKEY).length -lt 1){
    write-output "environment variable is not configured"
    Write-ToEventLog "environment variable is not configured" -errorlevel "information"
}

if($env:AZURE_IMAGE_ARCHIVE_SASKEY -eq $saskey){
    Write-Warning "environment variable is the same as the provided Saskey - please provide an updated SasKey"
    Write-ToEventLog "environment variable is the same as the provided Saskey - please provide an updated SasKey" -errorlevel "warning"
}

# set environment variable
[Environment]::SetEnvironmentVariable("AZURE_IMAGE_ARCHIVE_SASKEY", $saskey, [System.EnvironmentVariableTarget]::Machine)


# Extract the expiry time from the sasKey
$expiryTimeString = ($saskey -split '&') | Where-Object { $_ -like 'se=*' }

# Extract the actual expiry time value from the string
$expiryTimeValue = ($expiryTimeString -split '=')[1]

# Decode the URL-encoded datetime string
Add-Type -AssemblyName System.Web
$decodedExpiryTimeValue = [System.Web.HttpUtility]::UrlDecode($expiryTimeValue)

# Parse the decoded expiry time value as a datetime
$expiryTime = [datetime]::Parse($decodedExpiryTimeValue)

if ($expiryTime -lt (Get-Date).AddHours(1)) {
    write-error "SasKey has expired will expire in less than 1 hour"
    Write-ToEventLog -message "SasKey has expired or will expire in less than 1 hour" -errorlevel "error"
} 
elseif($expiryTime -lt (Get-Date).AddDays(7)){
    write-error "SasKey will expire in less than 7 days"
    Write-ToEventLog -message "SasKey will expire in less than 7 days" -errorlevel "error"    
}
elseif($expiryTime -lt (Get-Date).AddDays(30)){
    write-warning "SasKey will expire in less than 30 days"
    Write-ToEventLog -message "SasKey will expire in less than 30 days" -errorlevel "warning"
}
else {
    Write-Host "SasKey will expire in more than 30 days"
    Write-ToEventLog -message "SasKey will expire in more than 30 days" -errorlevel "information"

}