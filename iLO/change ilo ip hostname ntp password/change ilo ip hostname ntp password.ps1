#NEEDED
# Install-Module -Name HPEiLOCmdlets

### SETTINGS
$csv = "./change ilo ip hostname ntp password.csv"

$list = import-csv -Path $csv

#ask for first server number input
$server_number = Read-Host -Prompt "Input a server number (or 0 to exit)"

while($server_number -ne "0"){

	#get info from csv file
    $default_ip_address = $list.Where({$PSItem.server_number -eq $server_number}).default_ip_address
    $default_username = $list.Where({$PSItem.server_number -eq $server_number}).default_username
    $password_old = $list.Where({$PSItem.server_number -eq $server_number}).password_old
    $password_new = $list.Where({$PSItem.server_number -eq $server_number}).password_new
    $ip_address = $list.Where({$PSItem.server_number -eq $server_number}).ip_address
    $ip_subnet_mask = $list.Where({$PSItem.server_number -eq $server_number}).ip_subnet_mask
    $ip_gateway = $list.Where({$PSItem.server_number -eq $server_number}).ip_gateway
    $dns1 = $list.Where({$PSItem.server_number -eq $server_number}).dns1
    $dns2 = $list.Where({$PSItem.server_number -eq $server_number}).dns2
    $dns3 = $list.Where({$PSItem.server_number -eq $server_number}).dns3
    $hostname = $list.Where({$PSItem.server_number -eq $server_number}).hostname
    $domain = $list.Where({$PSItem.server_number -eq $server_number}).domain
    $ntp1 = $list.Where({$PSItem.server_number -eq $server_number}).ntp1
    $ntp2 = $list.Where({$PSItem.server_number -eq $server_number}).ntp2
    $iso_url = $list.Where({$PSItem.server_number -eq $server_number}).iso_url

	#run command
    echo "###Connecting to iLO..."
    $connection = Connect-HPEiLO -Address $default_ip_address -Username $default_username -Password $password_old -DisableCertificateAuthentication

    #show old settings
    echo "###Below are the old network settings"
    Get-HPEiLOIPv4NetworkSetting -Connection $connection

    #construct dns info
    $dnstype = ,@("Primary","Secondary","Tertiary")
    $dnsserver = ,@("$dns1","$dns2","$dns3")

    #apply IPv4 settings
    echo "###Applying network settings..."
    Set-HPEiLOIPv4NetworkSetting -Connection $connection -InterfaceType Dedicated -DHCPv4Enabled No -DHCPv4Gateway Disabled -DHCPv4DomainName Disabled -DHCPv4DNSServer Disabled -DHCPv4WINSServer Disabled -DHCPv4StaticRoute Disabled -DHCPv4NTPServer Disabled -IPv4Address $ip_address -IPv4SubnetMask $ip_subnet_mask -IPv4Gateway $ip_gateway -DNSName $hostname -DomainName $domain -DNSServerType $dnstype -DNSServer $dnsserver

    #disable IPv6
    Set-HPEiLOIPv6NetworkSetting -Connection $connection -InterfaceType Dedicated -PreferredProtocol Disabled  -StatelessAddressAutoConfiguration Disabled -DHCPv6StatefulMode Disabled -DHCPv6RapidCommit Disabled -DHCPv6StatelessMode Disabled -DHCPv6DomainName Disabled -DHCPv6DNSServer Disabled -DHCPv6SNTPSetting Disabled
    
    #apply ntp settings
    $sntp = ,@("$ntp1","$ntp2")
    Set-HPEiLOSNTPSetting -Connection $connection -InterfaceType Dedicated -DHCPv4NTPServer Disabled -DHCPv6NTPServer Disabled -PropagateTimetoHost Enabled -Timezone "Asia/Tokyo" -SNTPServer $sntp

    #set iLO default language to japanese
    #Set-HPEiLOLanguage -DefaultLanguage ja

    #set workload profile
    #Set-HPEBIOSWorkloadProfile -Connection $connection -WorkloadProfile VirtualizationMaximumPerformance

    #set virtual media for next reboot
    #Mount-HPEiLOVirtualMedia -Connection $connection -ImageURL $iso_url -Device CD
    #Set-HPEiLOVirtualMediaStatus -Connection $connection -VMBootOption BootOnNextReset -Device CD
    #Set-HPEiLOOneTimeBootOption -Connection $connection -BootSourceOverrideEnable Once -BootSourceOverrideTarget CD #Maybe needed?


    #RESTART SERVER HERE

    #change administrator password
    Set-HPEiLOAdministratorPassword -Connection $connection -Password $password_new

    #wait a little longer
    echo "###Waiting for 10 seconds..."
    Start-Sleep -Seconds 10

    #reset iLO
    echo "###Resetting iLO so new network settings take effect..."
    Reset-HPEiLO -Connection $connection -Device iLO -ResetType GracefulRestart

	#ask for new input
	$server_number = Read-Host -Prompt "Input the server number"

}