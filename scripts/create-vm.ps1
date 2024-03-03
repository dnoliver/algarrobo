param(
    [switch]$Elevated, # flag to check if we are running in elevated permissions
    [string]$vm, # name of VM, this just applies in Windows, it isn't applied to the OS guest itself.
    [string]$image, # path to disk image
    [string]$seed # path to disk image seed
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
        Start-Process powershell.exe -Verb RunAs -ArgumentList ("-noprofile -noexit -file {0} -elevated -vm $vm -image $image -seed $seed" -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'

# This script is in two parts. First we declare the variables to be applied.

$vmswitch = "Default Switch" # name of your local vswitch
$port = "port1" # port on the VM
$cpu = 4 # Number of CPUs
$ram = 10GB # RAM of VM. Note this is not a string, not in quotation marks
$disk_path = "$Env:ProgramData\Microsoft\Windows\Virtual Hard Disks\" # Where you want the VM's virtual disk to reside
$disk_size = 20GB # VM storage, again, not a string

# The following are the powershell commands

# Create a new VM
New-VM $vm

# Set the CPU and start-up RAM
Set-VM $vm -ProcessorCount $cpu -MemoryStartupBytes $ram

# Enable Nested Virtualization
Set-VMProcessor -VMName $vm -ExposeVirtualizationExtensions $true

# Create the new VHDX disk - the path and size.
New-VHD -Path $disk_path$vm-disk1.vhdx -SizeBytes $disk_size

# Add the new disk to the VM
Add-VMHardDiskDrive -VMName $vm -Path $disk_path$vm-disk1.vhdx

# Assign the OS ISO file to the VM
Set-VMDvdDrive -VMName $vm -Path $image

# Add the seed disk
Add-VMDvdDrive -VMName $vm -Path $seed

# Remove the default VM NIC named 'Network Adapter'
Remove-VMNetworkAdapter -VMName $vm

# Add a new NIC to the VM and set its name
Add-VMNetworkAdapter -VMName $vm -Name $port

# Connect the NIC to the vswitch
Connect-VMNetworkAdapter -VMName $vm -Name $port -SwitchName $vmswitch

# Configure Automatic Start Action to Nothing
Get-VM -VMName $vm | Set-VM -AutomaticStartAction Nothing

# Configure Automatic Stop Action to ShutDown
Get-VM -VMName $vm | Set-VM -AutomaticStopAction ShutDown

# Fire it up
Start-VM $vm
