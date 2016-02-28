# initilize demo env
Set-Location D:\Temp
$DemoVMname = "ws2016tp4"
$cred = Get-Credential -UserName "administrator" -Message "Please enter password"
$DemoVMPwd = ConvertTo-SecureString -AsPlainText $cred.GetNetworkCredential().Password -Force


# Create Demo windows TP3 VM with windows container
# .\New-ContainerHost.ps1 -VmName $DemoVMname -Password $DemoVMPwd

# Connect Demo VM through VMbus
# Enter-PSSession -VMName $DemoVMname -Credential $cred
# Exit-PSSession

# Assign External vSwitch to Demo VM
$DemoVM = Get-VM -Name $DemoVMname
$VMSwitch = ($DemoVM.NetworkAdapters).SwitchName

# Add Demo VM env to Local Demo Machine
$DemoVMIP = $DemoVM.NetworkAdapters.IPAddresses[0]
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $DemoVMIP -Force -Concatenate  
Get-Item WSMan:\localhost\Client\TrustedHosts

# Create PS Session to Demo VM 
$s = New-PSSession -ComputerName $DemoVMIP -Credential $cred

# Validate Demo VM Nested enabled
Get-VMProcessor -VM $DemoVM | select ExposeVirtualizationExtensions | Format-List 

# Copy Demo Script to Demo VM
Invoke-Command -Session $s -ScriptBlock {New-Item -ItemType Directory C:\DemoScripts -Force;Set-Location C:\DemoScripts}
Copy-Item -ToSession $s -Path .\DemoScript\*.ps1 -Destination c:\DemoScripts -Force


# Enter PS Session to Demo VM
Enter-PSSession -Session $s

# 重定向在本地通过PowerShell_ISE打开演示脚本
PSEdit Demo*Script.ps1
Exit-PSSession



