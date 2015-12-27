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


# 初始化演示环境设置设置Nano映像路径，构建BaseVHD路径以及Nano VHD路径
Set-Location $env:USERPROFILE\Work\ignite2016
$Suffix = 'NanoVM-'+ (Get-Random -Maximum 10)
$NanoVMName = $Suffix + '-' + (Get-Date -UFormat %y%m%d)
$BasePath = New-Item -ItemType Directory $NanoVMName -Force | Select-Object -ExpandProperty FullName
$ImagePath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\WindowsServerTP4.iso'

if (!(Get-DiskImage -ImagePath $ImagePath | Get-Volume)){ Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -PassThru }
$MediaPath = "$((Get-DiskImage -ImagePath $ImagePath | Get-Volume).DriveLetter)" + ":\"
$MediaDrive = $MediaPath.Split('\')[0]
$NanoVHD = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks"+"\"+"$NanoVMName.vhdx"

if ($CurrentVM = Get-VM -Name $NanoVMName -ErrorAction SilentlyContinue) {
    if ($CurrentVM.State -ne "Off") {
        Stop-VM -VM $CurrentVM -TurnOff -Force
    }
    Remove-VM -VM $CurrentVM -Force -Verbose
} 

Remove-Item -Path $NanoVHD  -Recurse -Force -ErrorAction SilentlyContinue


# 准备打包Nano VHD的脚本及运行环境
Copy-Item $MediaDrive\NanoServer\*.ps* .\ -Force
# Import-Module .\NanoServerImageGenerator.psm1 -Verbose
$TargetPath = $NanoVHD.Replace(" ","' '")
$ScriptBlock = "New-NanoServerImage -MediaPath $MediaPath -BasePath $BasePath -TargetPath $TargetPath -ComputerName $NanoVMName -GuestDrivers -ReverseForwarders  -Language 'en-us' -AdministratorPassword (ConvertTo-SecureString -String 'ignite2016' -Asplaintext -Force)"

# 创建Nano VHD，后期可以客户化（无人值守应答，加入域或静态IP设置等），演示中用到了最简单设置
Start-Process powershell.exe -Verb runas -ArgumentList "Import-Module .\NanoServerImageGenerator.psm1;$ScriptBlock"

# 创建Nano虚拟机
$vSwitchName = (Get-VMSwitch).Name
New-VM -Name $NanoVMName -MemoryStartupBytes 1GB -Generation 2 -VHDPath $NanoVHD -SwitchName $vSwitchName | Start-VM -Passthru



# 扩展项目
$NanoPWD = "ignite2016" | ConvertTo-SecureString -AsPlainText -Force
$Nanocred = new-object System.Management.Automation.PSCredential ("administrator",$NanoPWD)
$NanoVM = Get-VM -Name $NanoVMName
$NanoVMIP = $NanoVM.NetworkAdapters.IPAddresses[0]
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $NanoVMIP -Force -Concatenate  
$ns = New-PSSession -ComputerName $NanoVMIP -Credential $Nanocred
Copy-Item -ToSession $ns -Path .\aspnetv5web -Destination c:\ -Recurse -Force
# 将本地编译打包好的ASP.NET 5 项目拷贝到Nano服务器并解包
# Copy-Item -ToSession $ns -Path .\aspnetv5web.zip -Destination c:\ -Force
# $ArchModule = Join-Path (($env:PSMODULEPATH).Split(';') -match 'system32') -ChildPath "Microsoft.PowerShell.Archive"
# if (Test-Path $ArchModule){Copy-Item -ToSession $ns -Path $ArchModule -Destination $ArchModule -Recurse -Force}
Enter-PSSession -Session $ns

cat C:\aspnetv5web\approot\src\WebApplication9\project.json | findstr 'server.url'

if (!(Get-NetFirewallRule | where {$_.Name -eq "TCP8080"})) {
    New-NetFirewallRule -Name "TCP8080" -DisplayName "HTTP on TCP/8080" -Protocol tcp -LocalPort 8080 -Action Allow -Enabled True
}

# •NetSh Advfirewall set allprofiles state off

# 运行ASP.NET 5 WEB应用程序
Start-Process  .\aspnetv5web\approot\web.cmd

Exit-PSSession 

$NanoURI = $NanoVMIP + ":8080"
curl -Uri $NanoURI

# 清除演示环境
$NanoVM | Stop-VM -TurnOff -Force 
$NanoVM | Remove-VM -Force
if (Test-Path $NanoVHD){Remove-Item -Path $NanoVHD  -Recurse -Force -ErrorAction SilentlyContinue}
if (Test-Path $BasePath){Remove-Item -Path $BasePath -Recurse -Force -ErrorAction SilentlyContinue}
if (Test-Path $MediaPath){Dismount-DiskImage -ImagePath $ImagePath}