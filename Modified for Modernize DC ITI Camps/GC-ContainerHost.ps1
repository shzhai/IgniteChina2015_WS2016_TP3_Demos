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
   
   Set-Location -Path $env:USERPROFILE\Work\Ignite2016
   Write-Host -ForegroundColor Green ("Downloading https://aka.ms/newcontainerhost script to .\New-ContainerHost.ps1")
   Invoke-WebRequest -uri https://aka.ms/newcontainerhost -OutFile  .\New-ContainerHost.ps1
   
   if (Test-Path .\New-ContainerHost.ps1)
   {
        $ContainerScript = Get-Content -Raw .\New-ContainerHost.ps1
        $ErrorContent = 'PrimaryStatusDescription -eq "OK"'
        $CorrectContent = 'PrimaryStatusDescription -eq "确定"'
        $ContainerScript -replace $ErrorContent,$CorrectContent | Set-Content -Path .\New-ContainerHost.ps1 -Force 
   }

 $VMPWD = ConvertTo-SecureString -AsPlainText 'P@ssw0rd' -Force
 .\New-ContainerHost.ps1 -Password $VMPWD -VmName ContainerServer