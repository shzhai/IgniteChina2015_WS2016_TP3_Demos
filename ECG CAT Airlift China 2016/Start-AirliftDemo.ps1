# Init All Demo scripts and environment
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



Set-Location D:\Temp
Get-Item .\Demo*Script.ps1 | ForEach-Object {$psISE.CurrentPowerShellTab.Files.Add($($_.FullName))}

# docker images should include latest tag for each image if not we should tag them
# docker tag 6801d964fda5 windowsservercore:latest
# docker tat 8572198a60f1 nanoserver:latest