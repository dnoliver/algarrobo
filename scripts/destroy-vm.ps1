param(
    [switch]$Elevated, # flag to check if we are running in elevated permissions
    [string]$vm # name of VM, this just applies in Windows, it isn't applied to the OS guest itself.
)

# Elevate permissions to administrator

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false) {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ("-noprofile -noexit -file {0} -elevated -vm $vm" -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'

# Stop the VM
Stop-VM $vm

# Remove VM Snapshots
Get-VMSnapshot -VMName $vm | Remove-VMSnapshot

# Wait a few seconds
Start-Sleep -Seconds 10

# Remove the Disk
Get-VMHardDiskDrive -VMName $vm | Select-Object Path | Remove-Item

# Remove the VM
Remove-VM $vm

# Exit
Exit-PSSession
