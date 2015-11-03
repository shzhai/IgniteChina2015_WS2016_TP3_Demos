# 这部分仅用作说明
# 首先提升权限打开Powershell控制台下载在本地虚拟机创建演示虚拟机的脚本，注意其中判断VM集成工具状态脚本如果chcp是936中文，需要修改为"确定"而不是"OK"
# Get-VMIntegrationService |? Id -match "84EAAE65-2F2E-45F5-9BB5-0E857DC8EB47").PrimaryStatusDescription
# start-process powershell -Verb runAs
# Invoke-WebRequest -uri https://aka.ms/newcontainerhost -OutFile New-ContainerHost.ps1

# initilize demo env
Set-Location $env:HOMEPATH\Work\Ignite2016
$DemoVMname = "IgniteDemoHost1"
$cred = Get-Credential -UserName "administrator" -Message "Please enter password"
$DemoVMPwd = $cred.GetNetworkCredential().Password

# Create Demo windows TP3 VM with windows container
.\New-ContainerHost.ps1 -VmName $DemoVMname -Password $DemoVMPwd

# Connect Demo VM through VMbus
Enter-PSSession -VMName $DemoVMname -Credential $cred

# Redirect PS ise to Local 
# psedit test.ps1

# Assign External vSwitch to Demo VM
$DemoVM = Get-VM -Name $DemoVMname
$VMSwitch = Get-VMSwitch
$DemoVMNetAdaptor = Get-VMNetworkAdapter -VM $DemoVM
Connect-VMNetworkAdapter -VMNetworkAdapter $DemoVMNetAdaptor[0] -VMSwitch $VMSwitch

# Add Demo VM env to Local Demo Machine
$DemoVMIP = $DemoVM.NetworkAdapters.IPAddresses[0]
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $DemoVMIP -Force -Concatenate  
Get-Item WSMan:\localhost\Client\TrustedHosts

# Create PS Session to Demo VM 
$s = New-PSSession -ComputerName $DemoVMIP -Credential $cred

# Copy Demo Script to Demo VM
Invoke-Command -Session $s -ScriptBlock {New-Item -ItemType Directory C:\DemoScripts -Force;Set-Location C:\DemoScripts}
Copy-Item -ToSession $s -Path .\Demo*Script.ps1 -Destination c:\DemoScripts


# Enter PS Session to Demo VM
Enter-PSSession -Session $s

# 重定向在本地通过PowerShell_ISE打开演示脚本
PSEdit Demo*Script.ps1
