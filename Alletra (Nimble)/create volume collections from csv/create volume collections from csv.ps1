### SETTINGS
$storage_hostname = "3.3.3.3" #Nimble / Alletra IP address
$storage_username = "admin"
$storage_password = "mypassword"
$csv_file = ".\create volume collections from csv.csv"
$csv_datatypes = @{enabled=[int];volcoll_name=[string];vol_name=[string];schedule_name=[string];schedule_interval=[string];schedule_days=[string];schedule_time=[int];max_snapshots=[int]} #List of the data types for CSV entries

$vcenter_hostname = "1.1.1.1"
$vcenter_username = "administrator@vsphere.local"
$vcenter_password = "mypassword"


###CSV
#enabled = 0 for disabled, 1 for enabled
#volcoll_name = name for the volume collection to be created
#vol_name = name of the volume to be added to the created volume collection
#schedule_name = name of the schedule in the volume collection
#schedule_interval = days or weeks
#schedule_days = sunday,monday,tuesday,wednesday,thursday,friday,saturday
#schedule_time = 36000 for 10am
#max_snapshots = maximum number of snapshots to exist per volume in this volume collection


try {

    ### NEEDED STUFF
    # Install-Module -Name HPEAlletra6000andNimbleStoragePowerShellToolkit

    ### IMPORT MODULES
    Import-Module HPEAlletra6000andNimbleStoragePowerShellToolkit


    ### Connect to Nimble / Alletra
    $secure_storage_password = ConvertTo-SecureString -String $storage_password -AsPlainText -Force
    $storage_credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $storage_username, $secure_storage_password
    Connect-NSGroup -group $storage_hostname -credential $storage_credentials -IgnoreServerCertificate

    # Import VolumeList.csv
    Import-Csv $csv_file | Foreach-Object { 
	    Write-Host "`n###Creating a Volume with the following values:`n"
	    #Look up CSV column data types in CSVdatatypes and set them
	    foreach ($property in $_.PSObject.Properties) {
		    $property.Value = $property.Value -as $csv_datatypes[$property.Name]
		    Write-Host "Value: $($property.Value) Type: $($property.Value.GetType())"
	    }
	
	    if ( $_.enabled -eq 1 ) {

            echo "### creating volume collection $_.volcoll_name"
            New-NSVolumeCollection -name $_.volcoll_name -app_sync vmware -vcenter_hostname $vcenter_hostname -vcenter_username $vcenter_username -vcenter_password $vcenter_password

            echo "### creating protection schedule $_.schedule_name for volume collection $_.volcoll_name"
            New-NSProtectionSchedule -name $_.schedule_name -volcoll_or_prottmpl_type volume_collection -volcoll_or_prottmpl_id $(Get-NSVolumeCollection -name $_.volcoll_name).id -period_unit $_.schedule_interval -period 1 -days $_.schedule_days -at_time $_.schedule_time -num_retain $_.max_snapshots

            echo "### adding volume $_.vol_name to volume collection $_.volcoll_name"
            Set-NSVolume -id $(Get-NSVolume -name $_.vol_name).id -volcoll_id $(Get-NSVolumeCollection -name $_.volcoll_name).id

            echo "### testing volume collection $_.volcoll_name"
            Test-NSVolumeCollection -id $(Get-NSVolumeCollection -name $_.volcoll_name).id

		    Read-Host -Prompt "`nOK? Press any key to continue"
	    }	
    }
    Write-Host "`nFinished!"
    pause
}
catch {
    Write-Host "An Error Occured!" -ForegroundColor RED
    exit 1
}

finally {
    $Error.Clear()
}