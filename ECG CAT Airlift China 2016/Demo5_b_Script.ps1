# 初始化演示环境设置设置Nano映像路径，构建BaseVHD路径以及Nano VHD路径
$DemoPath = 'D:\Temp'
Set-Location $DemoPath
$Suffix = 'NanoVM-'+ (Get-Random -Maximum 10)
$NanoVMName = $Suffix + '-' + (Get-Date -UFormat %y%m%d)
$BasePath = New-Item -ItemType Directory $NanoVMName -Force | Select-Object -ExpandProperty FullName
$ImagePath = "$DemoPath\ws2016tp4en.iso"

$DefaultVHD = Get-VMHost | select -ExpandProperty VirtualHardDiskPath
if (!(Get-DiskImage -ImagePath $ImagePath | Get-Volume)){ Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -PassThru }
$MediaPath = "$((Get-DiskImage -ImagePath $ImagePath | Get-Volume).DriveLetter)" + ":\"
$MediaDrive = $MediaPath.Split('\')[0]
$NanoVHD = "$DefaultVHD\$NanoVMName.vhdx"

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
$ScriptBlock = "New-NanoServerImage -MediaPath $MediaPath -BasePath $BasePath -TargetPath $TargetPath -ComputerName $NanoVMName -GuestDrivers -ReverseForwarders  -Language 'en-us' -AdministratorPassword (ConvertTo-SecureString -String 'airliftchina' -Asplaintext -Force)"

# 创建Nano VHD，后期可以客户化（无人值守应答，加入域或静态IP设置等），演示中用到了最简单设置
Start-Process powershell.exe -Verb runas -ArgumentList "Import-Module .\NanoServerImageGenerator.psm1;$ScriptBlock"

# 创建Nano虚拟机
$vSwitchName = (Get-VMSwitch).Name[0]
New-VM -Name $NanoVMName -MemoryStartupBytes 1GB -Generation 2 -VHDPath $NanoVHD -SwitchName $vSwitchName | Start-VM -Passthru



# 扩展项目
$NanoPWD = "airliftchina" | ConvertTo-SecureString -AsPlainText -Force
$Nanocred = new-object System.Management.Automation.PSCredential ("administrator",$NanoPWD)
$NanoVM = Get-VM -Name $NanoVMName
$NanoVMIP = $NanoVM.NetworkAdapters.IPAddresses[0]
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $NanoVMIP -Force -Concatenate  
$ns = New-PSSession -ComputerName $NanoVMIP -Credential $Nanocred
# Copy-Item -ToSession $ns -Path .\aspnetv5web -Destination c:\ -Recurse -Force
# 将本地编译打包好的ASP.NET 5 项目拷贝到Nano服务器并解包
# Copy-Item -ToSession $ns -Path .\aspnetv5web.zip -Destination c:\ -Force
# $ArchModule = Join-Path (($env:PSMODULEPATH).Split(';') -match 'system32') -ChildPath "Microsoft.PowerShell.Archive"
# if (Test-Path $ArchModule){Copy-Item -ToSession $ns -Path $ArchModule -Destination $ArchModule -Recurse -Force}

# Make sure 本地编译打包好的ASP.NET 5 项目vhdx virtual disk拷贝到Nano server default vhd path, 
# demo used demovhd.vhdx to contain the project
Add-VMHardDiskDrive -VM $NanoVM -Path $DefaultVHD\demovhd.vhdx

Enter-PSSession -Session $ns
# [char[]](67..90) | Where-Object {(Get-PSDrive $_ -ErrorAction Ignore)} | Select-Object -Last 1 -OutVariable diskletter
Get-Volume -filesystemlabel 'democode' | Select-Object -ExpandProperty DriveLetter -OutVariable projectdisk



cat $diskletter':'\aspnetv5web\approot\src\WebApplication9\project.json | findstr 'server.url'

if (!(Get-NetFirewallRule | where {$_.Name -eq "TCP8080"})) {
    New-NetFirewallRule -Name "TCP8080" -DisplayName "HTTP on TCP/8080" -Protocol tcp -LocalPort 8080 -Action Allow -Enabled True
}

# NetSh Advfirewall set allprofiles state off

# 运行ASP.NET 5 WEB应用程序
Start-Process  $diskletter':'\aspnetv5web\approot\web.cmd

Exit-PSSession 

$NanoURI = "$($NanoVMIP):8080"
curl -Uri $NanoURI

Start-Process {iexplore.exe} -ArgumentList "http://$NanoURI"

# 清除演示环境
$NanoVM | Stop-VM -TurnOff -Force 
$NanoVM | Remove-VM -Force
if (Test-Path $NanoVHD){Remove-Item -Path $NanoVHD  -Recurse -Force -ErrorAction SilentlyContinue}
if (Test-Path $BasePath){Remove-Item -Path $BasePath -Recurse -Force -ErrorAction SilentlyContinue}
if (Test-Path $MediaPath){Dismount-DiskImage -ImagePath $ImagePath}