# Check currnt ISE env if not in Admin mode promote to admin mode and run
$CurrentEnv = $Host.Name

 # Check to see if we are currently running in PowerShell ISE
 if ($CurrentEnv -ne 'Windows PowerShell ISE Host')
    {
    # We are not running "as Administrator" - so relaunch as administrator in PowerShell for this Script
    
    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell_ISE";
    
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;

    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";
    
    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);
    
    # Exit from the current, unelevated, process
    exit
    }

 # Get the ID and security principal of the current user account
 $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
 # Get the security principal for the Administrator role
 $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
 if ( -not $myWindowsPrincipal.IsInRole($adminRole)) {
     
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell_ISE";
     
    $newProcess.Verb = "runas";

    $ScriptPath = $psISE.CurrentFile.FullPath

    $newProcess.Arguments = "$ScriptPath";

    [System.Diagnostics.Process]::Start($newProcess);
    
    exit

 }

# initilize demo env
Set-Location $env:HOMEPATH\Work\Ignite2016
$DemoVMname = "ContainerServer"
$cred = Get-Credential -UserName "administrator" -Message "Please enter password"
$DemoVMPwd = ConvertTo-SecureString -AsPlainText $cred.GetNetworkCredential().Password -Force


# Create Demo windows TP3 VM with windows container
# .\New-ContainerHost.ps1 -VmName $DemoVMname -Password $DemoVMPwd

# Connect Demo VM through VMbus
Enter-PSSession -VMName $DemoVMname -Credential $cred

# Redirect PS ise to Local 
# psedit test.ps1

# Assign External vSwitch to Demo VM
$DemoVM = Get-VM -Name $DemoVMname
$VMSwitch = Get-VMSwitch
# $DemoVMNetAdaptor = Get-VMNetworkAdapter -VM $DemoVM
# Connect-VMNetworkAdapter -VMNetworkAdapter $DemoVMNetAdaptor[0] -VMSwitch $VMSwitch

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
