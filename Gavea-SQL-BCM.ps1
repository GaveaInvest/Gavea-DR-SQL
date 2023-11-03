<#
.Synopsis
   Gavea scripts to change Azure VM SQL server and SQL Agent/permission
.DESCRIPTION
   This script will:
   1- Download scripts
   2- Update/change MSSQLSERVER/MSSQLAGENT Windows service account (restart SQL and Agent services)
   3- Add local\Administrators group as sa (restart SQL and Agent services)
   4- Run sql-cmd tempdb.sql for details (restart SQL and Agent services)
   5- Download sql backups from blobstorage
.EXAMPLE
   powershell -ExecutionPolicy Unrestricted -File Gavea-SQL-BCM.ps1 -UName "Domain\user" -PWord "P@ssw0rd!" -artifactsLocation "https://raw.githubusercontent.com/GaveaInvest/Gavea-DR-SQL/master" -blobStorageAccountName "stgbcmsql" -blobStorageAccountKey "key" -blobStorageAccountNameDiff "stgbcmsqldiff" -blobStorageAccountKeyDiff "key""
.INPUTS
   -UName "Domain\user"
   -PWord "P@ssw0rd!"
   -artifactsLocation "https://raw.githubusercontent.com/GaveaInvest/Gavea-DR-SQL/master"
   -blobStorageAccountName "stgbcmsql"
   -blobStorageAccountKey "key"
   -blobStorageAccountNameDiff "stgbcmsqldiff"
   -blobStorageAccountKeyDiff "keydiff"
.OUTPUTS
   NONE
.NOTES
   Source https://dba.stackexchange.com/questions/22006/how-to-change-sql-server-service-account-using-ps
.FUNCTIONALITY
   Download files from public repo
   Update MSSQLSERVER and SQLSERVERAGENT Windows services accounts
   Add windows local\Administrators as sa
   Run sql-cmd scripts
   download files from private repository
   to infinity and beyond (lol)
#>



Param (
    [string]$UName,
    [string]$PWord,
    [string]$artifactsLocation = "https://raw.githubusercontent.com/GaveaInvest/Gavea-DR-SQL/master",
    [string]$blobStorageAccountName = "stgbcmsql",
    [string]$blobStorageAccountKey,
    [string]$blobStorageAccountNameDiff = "stgbcmsqldiff",
    [string]$blobStorageAccountKeyDiff
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
$ErrorActionPreference="continue"

$Server = $env:COMPUTERNAME #Enter the name of SQL Server Instance
New-Item -Path "C:\WindowsAzure\Logs\Gavea-SQL-BCM" -ItemType directory | Out-Null
function log($string, $color)
{
if ($Color -eq $null) {$color = "white"}
#cd C:\WindowsAzure\Logs
#$Loc = Get-Location
$Date = Get-Date -format yyyyMMdd
$logfile = "C:\WindowsAzure\Logs\Gavea-SQL-BCM\log" + $Date + ".txt"

write-host $string -foregroundcolor $color
$temp = ": " + $string
$string = Get-Date -format "yyyy.MM.dd hh:mm:ss tt"
$string += $temp
$string | out-file -Filepath $logfile -append
}
function changesvcaccount {
    log "Starting Function 'changesvcaccount' to change Windows Services MSSQLSERVER and SQLSERVERAGENT service accounts" red
    $SMOWmiserver = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $Server #Suck in the server you want
    #These just act as some queries about the SQL Services on the machine you specified.
    #$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-Table
    #Same information just pivot the data
    #$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-List

    #Specify the "Name" (from the query above) of the one service whose Service Account you want to change.
    log "Preparing to change MSSQLSERVER service account" green
    $ChangeService1=$SMOWmiserver.Services | where {$_.name -eq "MSSQLSERVER"} #Make sure this is what you want changed!
    log "Preparing to change SQLSERVERAGENT service account" green
    $ChangeService2=$SMOWmiserver.Services | where {$_.name -eq "SQLSERVERAGENT"} #Make sure this is what you want changed!

    #Check which service you have loaded first
    #$ChangeService1
    #$ChangeService2

    #change services accounts
    log "Changing MSSQLSERVER service account" green
    $ChangeService1.SetServiceAccount($UName, $PWord)
    log "Changing SQLSERVERAGENT service account" green
    $ChangeService2.SetServiceAccount($UName, $PWord)

    #set startup auto
    log "Changing MSSQLSERVER service startup" green
    Set-Service -name MSSQLSERVER -StartupType Automatic
    log "Changing SQLSERVERAGENT service startup" green
    Set-Service -name SQLSERVERAGENT -StartupType Automatic

    #ReStart services
    log "Restarting MSSQLSERVER service" green
    ReStart-Service MSSQLSERVER -Force
    log "Restarting MSSQLSERVER service" green
    ReStart-Service SQLSERVERAGENT -Force

    log "Finished function Function 'changesvcaccount'" red
}


function addlocaladministrators {
    log "Starting Function 'addlocaladministrators' to add LOCALHOST\ADMINISTRATORS as MSSQL sa" red
    log "Stopping SQLSERVERAGENT service" green
    Stop-Service SQLSERVERAGENT -Force
    log "Stopping MSSQLSERVER service" green
    Stop-Service MSSQLSERVER -Force
    #NET STOP $ServiceName 
    log "Starting MSSQLSERVER /mSQLCMD" green
    NET START MSSQLSERVER /mSQLCMD 
    #Start-Service MSSQLSERVER /mSQLCMD
    log "Running SQLCMD to add Administrators as sysadmin" green
    SQLCMD -S $Server -Q "if not exists(select * from sys.server_principals where name='BUILTIN\administrators') CREATE LOGIN [BUILTIN\administrators] FROM WINDOWS;EXEC master..sp_addsrvrolemember @loginame = N'BUILTIN\administrators', @rolename = N'sysadmin'"
    log "Restarting MSSQLSERVER service" green
    Restart-Service MSSQLSERVER -Force
    log "Starting SQLSERVERAGENT service" green
    Start-Service SQLSERVERAGENT

    $execute = SQLCMD -S $Server -Q "if exists( select * from fn_my_permissions(NULL, 'SERVER') where permission_name = 'CONTROL SERVER') print 'You are a sysadmin.'" 
    log($execute)

}

function downloadscript {
    $fileToInstall = "Gavea-sqlscript.sql"
    $source = $artifactsLocation + "/" + $fileToInstall
    $dest = "C:\WindowsAzure\sqlscript"
    New-Item -Path $dest -ItemType directory
    Invoke-WebRequest $source -OutFile "$dest\$fileToInstall"
}
function runsqlscript {
    log "Starting Function 'runsqlscript' to move TEMPDB data and log files to new location" red
    log "Stopping SQLSERVERAGENT service" green
    Stop-Service SQLSERVERAGENT -Force
    log "Stopping MSSQLSERVER service" green
    Stop-Service MSSQLSERVER -Force
    log "Creating folder F:\TempDB\" green
    New-Item -Path "F:\TempDB\" -ItemType directory | Out-Null
    log "Starting MSSQLSERVER /mSQLCMD" green
    NET START MSSQLSERVER /mSQLCMD 
    #Start-Service MSSQLSERVER /mSQLCMD
    log 'starting sql script SQLCMD -S $Server -i C:\WindowsAzure\sqlscript\Gavea-sqlscript.sql -o C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt' green
    SQLCMD -S $Server -i C:\WindowsAzure\sqlscript\Gavea-sqlscript.sql -o C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt
    log(cat C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt)
    log "Restaring SQL Service to apply new tempdb location.." green
    Restart-Service MSSQLSERVER -Force
    log "Starting SQLSERVERAGENT service" green
    Start-Service SQLSERVERAGENT
}

function initProvider {
    log "Installing latest Nuget" green
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    log "Installing latest AzureRM" green
    Install-Module -Name AzureRM -Repository PSGallery -Force
}

function downloadblob {
    log "Starting Function 'downloadblob' to download blob data [SQL backups] to F:\backups" red
    log "Creating folder G:\backups\" green
    New-Item -Path "G:\backups\" -ItemType directory | Out-Null
    log "Setup AzureStorageContext" green
    $ctx = New-AzureStorageContext -StorageAccountName $blobStorageAccountName -StorageAccountKey $blobStorageAccountKey
    $ctxDiff = New-AzureStorageContext -StorageAccountName $blobStorageAccountNameDiff -StorageAccountKey $blobStorageAccountKeyDiff
    $ContainerNameDiff = "diff-backups"
    $ContainerNameFull = "full-backups"
    $downloadblobDirectory = "G:\backups\"
    log "Downloading differential backups" green
    Get-AzureStorageBlob -Container $ContainerNameDiff -Context $ctxDiff | Where-Object SnapshotTime -eq $null | Get-AzureStorageBlobContent -Destination $downloadblobDirectory -Context $ctxDiff
    log "Downloading full backups" green
    Get-AzureStorageBlob -Container $ContainerNameFull -Context $ctx | Where-Object SnapshotTime -eq $null | Get-AzureStorageBlobContent -Destination $downloadblobDirectory -Context $ctx
    log "finish downloadblob function" green
}
function downloadPostDeployScripts {
    log "Starting Function 'downloadPostDeployScripts' to download post-install sql scripts [post-deploy-scripts] to F:\sqlScripts" red
    log "Creating folder F:\sqlScripts\" green
    New-Item -Path "F:\sqlScripts\" -ItemType directory | Out-Null
    log "Setup AzureStorageContext" green
    $ctx = New-AzureStorageContext -StorageAccountName $blobStorageAccountName -StorageAccountKey $blobStorageAccountKey
    $ContainerName = "post-deploy-scripts"    
    $downloadDirectory = "F:\sqlScripts\"
    log "Downloading post-install sql scripts" green
    Get-AzureStorageBlob -Container $ContainerName -Context $ctx | Where-Object SnapshotTime -eq $null | Get-AzureStorageBlobContent -Destination $downloadDirectory -Context $ctx
    log "finish downloadPostDeployScripts function" green
}

function runPostDeployScripts {
    log "Starting Function 'runPostDeployScripts' to initiate the restore process" red
    log "Creating folder F:\DATA\" green
    New-Item -Path "F:\DATA\" -ItemType directory | Out-Null
    log "Creating folder F:\LOG\" green
    New-Item -Path "F:\LOG\" -ItemType directory | Out-Null
    log "Creating folder G:\LOG\" green
    New-Item -Path "G:\LOG\" -ItemType directory | Out-Null
    log "Creating folder D:\TEMPDB\" green
    New-Item -Path "D:\TEMPDB" -ItemType directory | Out-Null
    foreach ($scriptFile in Get-ChildItem "F:\sqlScripts\" | Sort-Object | Select-Object -ExpandProperty FullName) 
    {
        log "starting sql script SQLCMD -S $Server -i $scriptFile -o $scriptFile.rpt" green
        SQLCMD -S $Server -i $scriptFile -o "$scriptFile.rpt"
        log(cat "$scriptFile.rpt")
    }
}

downloadscript
changesvcaccount
addlocaladministrators
#runsqlscript
initProvider
downloadblob
downloadPostDeployScripts
runPostDeployScripts
log "Finished Gavea-SQL-BCM script" red
