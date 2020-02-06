# Create a new Azure virtual machine with SQL image and join into an existing AD Domain

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fd13g0s0uz4%2fGavea-DR-SQL%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fd13g0s0uz4%2fGavea-DR-SQL%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/AzureGov.png"/>
</a>

This template allows you to create a new Azure virtual machine with SQL image and join into an existing Windows Active Directory Domain.

## For this template to work we need the following prerequisites to be met:

1. An Active Directory Forest must exist and a Domain Controller must be accessible by the virtual machine either on-premises or in Azure
2. The user that is required in this template must have the necessary rights to join computers to an Active Directory Domain
3. Domain DNS Name must be resolved by the virtual machine

## Details about some of the parameters:

1. existingSubnetID - Existing subnet ID to deploy VM, this subnet must have connectivity with AD Domain
1. virtualMachineName - Unique hostname for VM deployment. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to '^[a-z][a-z0-9-]{1,61}[a-z0-9]$'.
2. virtualMachineSize - The size of the virtual machines, example 'Standard_E16s_v3'
3. existingVnetResourceGroup - Existing resource group that contains the virtual network
4. existingVirtualNetworkName - Existing virtual network name
5. existingSubnetName - Existing subnet name
6. imageOffer - Windows Server and SQL Offer from publisher MicrosoftSQLServer
7. sqlSku - SQL Server Sku
8. adminUsername - The name of the local administrator of the new VM. Exclusion list: 'admin','administrator
9. adminPassword - The password for the local administrator account of the new VM
10. storageWorkloadType - SQL Server Workload Type
11. sqlDataDisksCount - Amount of data disks (1TB each) for SQL Data files
12. dataPath - Path for SQL Data files. Please choose drive letter from F to Z, and other drives from A to E are reserved for system
13. sqlLogDisksCount - Amount of data disks (1TB each) for SQL Log files
14. logPath - Path for SQL Log files. Please choose drive letter from F to Z and different than the one used for SQL data. Drive letter from A to E are reserved for system
15. location - Azure location (region) for all resources
16. sqlConnectivityType - SQL Server Virtual Machine SQL Connectivity Type
17. sqlPortNumber - SQL Server Virtual Machine SQL Port Number
18. sqlAuthenticationLogin - SQL Server Authentication Login Account Name 
19. sqlAuthenticationPassword - SQL Server Authentication Login Account Password
20. domainToJoin - FQDN of the existing AD domain
21. domainUsername - Account used to join the VM on domain
22. domainPassword - Password to join the VM on domain
23. ouPath - Specifies an organizational unit (OU) for the computer domain account. Enter the full distinguished name of the OU in quotation marks. Example: \"OU=testOU; DC=domain; DC=Domain; DC=com\"
24. domainJoinOptions - Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx
25. UName - Windows Service account used by MSSQLSERVER and SQLSERVERAGENT services name
26. PWord - Windows Service account used by MSSQLSERVER and SQLSERVERAGENT services Password
27. _artifactsLocation - The base URI where powershell script to update sql used. When the template is deployed using the accompanying scripts.
28. blobStorageAccountName - blobStorageAccount with SQL backups.
29. blobStorageAccountNameDiff - blobStorageAccount with Diff SQL backups.
30. blobStorageAccountKey - blobStorageAccount access key, this key will be used to access blobStorageAccountName data.
31. blobStorageAccountKey - blobStorageAccount Diff access key, this key will be used to access blobStorageAccountName Diff data.


## Templates used as source information:
https://github.com/d13g0s0uz4/azure-quickstart-templates/tree/master/101-sql-vm-new-storage
https://github.com/d13g0s0uz4/azure-quickstart-templates/tree/master/201-vm-domain-join
https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-windows-copy-datadisks


## Docs:
### SQL
https://docs.microsoft.com/en-us/azure/templates/microsoft.sqlvirtualmachine/2017-03-01-preview/sqlvirtualmachines
### AD Join
https://docs.microsoft.com/bs-latn-ba/Azure/active-directory-domain-services/join-windows-vm-template
### Custom Scripts
https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows



