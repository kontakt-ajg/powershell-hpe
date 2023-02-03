### NEEDED STUFF
# Install-Module -Name HPEAlletra6000andNimbleStoragePowerShellToolkit

### SETTINGS
$StorageIPAddress = "3.3.3.3" #Nimble / Alletra IP address
$StorageUsername = "admin" #Nimble / Alletra username; password will be asked during runtime
$VolumeListCSVPath = (Get-Item $PSCommandPath ).DirectoryName+"\"+(Get-Item $PSCommandPath ).BaseName+".csv"
$CSVdatatypes = @{enabled=[int];name=[string];size=[int];dedupe_thin=[int];perf_pol=[string];multi_init=[int];init_group=[string]} #List of the data types for CSV entries

### VolumeList.csv structure
#enabled : int : 0 = skip; 1 = create
#name : string : 
#size : int : size in MB, 1024 = 1GB
#dedupe_thin : int : 0 = thick; 1 = thin + dedupe
#perf_pol : string : 
#multi_init : int : 0 = disabled; 1 = enabled
#init_group : string : 


### IMPORT MODULES
Import-Module HPEAlletra6000andNimbleStoragePowerShellToolkit


### Connect to Nimble / Alletra
Connect-NSGroup -group $StorageIPAddress -credential $StorageUsername -IgnoreServerCertificate


# Import VolumeList.csv
Import-Csv $VolumeListCSVPath | Foreach-Object { 
	Write-Host "`n###Creating a Volume with the following values:`n"
	#Look up CSV column data types in CSVdatatypes and set them
	foreach ($property in $_.PSObject.Properties) {
		$property.Value = $property.Value -as $CSVdatatypes[$property.Name]
		Write-Host "Value: $($property.Value) Type: $($property.Value.GetType())"
	}
	
	if ( $_.enabled -eq 1 ) {
        Write-Host "`nCreating Volume $($_.name) ...`n"
		New-NSVolume -name $_.name -size $_.size -thinly_provisioned $_.dedupe_thin -dedupe_enabled $_.dedupe_thin -perfpolicy_id $(Get-NSPerformancePolicy -name $_.perf_pol).id -multi_initiator $_.multi_init

        Write-Host "`nMapping Volume $($_.name) to Initiator Group $($_.init_group) ...`n"
		New-NSAccessControlRecord -initiator_group_id $(Get-NSInitiatorGroup -name $_.init_group).id -vol_id $(Get-NSVolume -name $_.name).id

        Write-Host "`nChecking Volume $($_.name) ...`n"		
        Get-NSVolume -name $_.name
		
		Read-Host -Prompt "`nOK? Press any key to continue"
	}	
	#$_   # return the modified object
}
Write-Host "`nFinished!"
pause
