# Demo Hyper-v Nano container instances in Local Hyper-V Host
$ConHostSwitch = (Get-VMSwitch).Name[1]

# Create one Hyper-v Nano container
New-Container -Name HYPVCON1 -ContainerImageName NanoServer -SwitchName $ConHostSwitch -RuntimeType HyperV 

# Create Normal Nano container
New-Container -Name HYPVCON2 -ContainerImageName nanoserver -SwitchName $ConHostSwitch -RuntimeType Default 

Get-Container | Select ContainerName, RuntimeType

# Convert Normal Nano container to Hyper-v container
Set-Container -Name HYPVCON2 -RuntimeType HyperV

Get-Container | Select ContainerName, RuntimeType

Get-Container | Select Name, RuntimeType, ContainerID | Where {$_.RuntimeType -eq 'Hyperv'}


# Total csrss process number
get-process | where {$_.ProcessName -eq 'csrss'}

# Start all hyper-v container and check process of the containers
Get-Container -Name HYPVCON1,HYPVCON2 | Start-Container

Get-Process -name vmwp # virtual machine windows process

# Check all those container IDs can be found from computer processes list
Get-Container | select -ExpandProperty ContainerId | % {Get-ComputeProcess -Id $_}

# Identify isolated hyper-v containers compart with Normal container
Get-Process | where {$_.ProcessName -eq 'csrss'}

Get-Process -Name lsass | Measure-Object # This lsass process should remain 1 as only Local host process is there, compare to nomral Demo 1 present result

# Get Nomral container local process id 
New-Container -Name WINCONT -ContainerImageName WindowsServerCore -SwitchName $ConHostSwitch 

Start-Container -Name WINCONT

Get-Process -Name lsass | Measure-Object # Now you can find out the new lsass from default windows container born


$WINCON = Get-Container -Name WINCONT

# Let's dive in the container and find out the csrss process
$WINCONID = Invoke-Command -ContainerId $WINCON.ContainerId -RunAsAdministrator -ScriptBlock { Get-Process | where {$_.ProcessName -eq 'csrss'} }

# local csrss process exist in container host, you can find the same ID appear in Local Host task list
Get-Process | Where-Object {$_.Id -eq $WINCONID.Id}

# Total csrss process number add one here
get-process | where {$_.ProcessName -eq 'csrss'} | Measure-Object

# Check if csrss process exit in container host
$HYPVCON1 = Get-Container -Name HYPVCON1

Enter-PSSession -ContainerId $HYPVCON1.ContainerId -RunAsAdministrator 
get-process | where {$_.ProcessName -eq 'csrss'} | select Id,ProcessName | fl
Exit-PSSession

get-process | where {$_.ProcessName -eq 'csrss'} | select Id,ProcessName | fl


# remove all containers 
Get-Container | Stop-Container -TurnOff  
Get-Container | Remove-Container -Force