# required
# Install-Module -Name HPEAlletra6000andNimbleStoragePowerShellToolkit
# https://www.powershellgallery.com/packages/HPEAlletra6000andNimbleStoragePowerShellToolkit/3.4.1

# settings
[string][ValidateNotNullOrEmpty()] $ip_address = "3.3.3.3"
[string][ValidateNotNullOrEmpty()] $username = "admin"
[string][ValidateNotNullOrEmpty()] $password = "mypassword"
[string][ValidateNotNullOrEmpty()] $volume_name = "myVolume"
[bool][ValidateNotNullOrEmpty()] $vss_enabled = $true #for VSS application-synchronized snapshot must be set to $true
[int][ValidateNotNullOrEmpty()] $max_snapshots = 7 #IF VOLUME COLLECTIONS ARE USED IT MUST BE HIGHER THAN THE LIMIT OF VOLCOLL SNAPSHOTS
[string][ValidateNotNullOrEmpty()] $snapshot_name_prefix = "script-"
[string][ValidateNotNullOrEmpty()] $snapshot_name = $snapshot_name_prefix + $(Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
[string][ValidateNotNullOrEmpty()] $log_file = "C:\Users\myUser\Desktop\" + "$snapshot_name.log"

try {
    Start-Transcript -Append $log_file

    echo ""
    echo ""
    echo "### START OF SCRIPT"
    echo ""
    echo ""

    #connect to alletra or nimble
    echo "###### CONNECTING ######"
    echo ""
    echo "### connecting to alletra or nimble..."
    echo ""

    $secure_password = ConvertTo-SecureString -String $password -AsPlainText -Force
    $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $secure_password
    Connect-NSGroup -group $ip_address -credential $credentials -IgnoreServerCertificate
    echo ""

    #count current snapshots
    $current_snapshots = (Get-NSSnapshot -vol_id $(Get-NSVolume -name $volume_name).id | measure).Count

    #if max snapshots reached then delete oldest 
    while ($current_snapshots -ge $max_snapshots) {
        echo "###### SNAPSHOT DELETION ######"
        echo ""
        echo "### (before) current snapshots: $current_snapshots"
        echo "### (before) max snapshots: $max_snapshots"
        echo ""

        $oldest_snapshot_number = $current_snapshots - 1
        #find the oldest snapshot created by this script
        do {
            echo "### searching for the oldest snapshots created by this script..."
            $oldest_snapshot_id = $(Get-NSSnapshot -vol_id $(Get-NSVolume -name $volume_name).id | Sort-Object creation_time -Descending | Select -Index $oldest_snapshot_number).id
            $oldest_snapshot_name = $(Get-NSSnapshot -id $oldest_snapshot_id).name
            $oldest_snapshot_number = $oldest_snapshot_number - 1
            if ($oldest_snapshot_name.Substring(0,$snapshot_name_prefix.length) -ne $snapshot_name_prefix) {
                echo "### skipping: $oldest_snapshot_name"
            } else {
                echo "### found: $oldest_snapshot_name"
            }
            echo ""
        } until ($oldest_snapshot_name.Substring(0,$snapshot_name_prefix.length) -eq $snapshot_name_prefix) 

        echo "### deleting oldest snapshots until current snapshots < max snapshots..."
        echo "### name:  $oldest_snapshot_name"
        echo "### id: $oldest_snapshot_id"
        echo ""
        Remove-NSSnapshot -id $oldest_snapshot_id

        #re-check snapshot count
        $current_snapshots = (Get-NSSnapshot -vol_id $(Get-NSVolume -name $volume_name).id | measure).Count
        echo "### (after) current snapshots: $current_snapshots"
        echo "### (after) max snapshots: $max_snapshots"
        echo ""
        echo ""
    }

    echo "###### SNAPSHOT CREATION ######"
    echo ""
    echo "### creating a new snapshot..."
    New-NSSnapshot -name $snapshot_name -vol_id $(Get-NSVolume -name $volume_name).id -writable $vss_enabled

    if( $? ) {
        echo ""
        $current_snapshots = (Get-NSSnapshot -vol_id $(Get-NSVolume -name $volume_name).id | measure).Count
        echo "### current snapshots: $current_snapshots"
        echo "### max snapshots: $max_snapshots"
        echo ""
        echo ""
        echo "### END OF SCRIPT"
        echo ""
        echo ""
        Stop-Transcript
        exit 0
    }
}
catch {
    Write-Host "An Error Occured!" -ForegroundColor RED
    Write-Host $_
    Stop-Transcript
    exit 1
}

finally {
    $Error.Clear()
}