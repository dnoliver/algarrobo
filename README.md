# Algarrobo

A test bed for Open vSwitch experiments

## Create Hosts

Prepare the ISO files to create the hosts:

```bash
cd cloud-init
docker compose -f compose-dev.yaml build app
docker compose -f compose-dev.yaml run \
    --rm --env CLOUD_INIT_HOSTNAME=host-1 --env SEED_LOCATION=./nfs/seed-1.iso app echo "Done"
docker compose -f compose-dev.yaml run \
    --rm --env CLOUD_INIT_HOSTNAME=host-2 --env SEED_LOCATION=./nfs/seed-2.iso app echo "Done"
```

Create the private virtual switch in Microsoft Hyper-V:

```ps1
Start-Process powershell.exe -Verb RunAs
New-VMSwitch -Name "Private Switch" -SwitchType private
```

Create the hosts in Microsoft Hyper-V:

```ps1
.\scripts\create-vm.ps1 -vm "host-1" `
    -image "$pwd\cloud-init\nfs\ubuntu-22.04.4-live-server-amd64.iso" `
    -seed "$pwd\cloud-init\nfs\seed-1.iso"
.\scripts\create-vm.ps1 `
    -vm "host-2" `
    -image "$pwd\cloud-init\nfs\ubuntu-22.04.4-live-server-amd64.iso" `
    -seed "$pwd\cloud-init\nfs\seed-2.iso"
```

## Configure Hosts

Create the Ansible Controller:

```bash
cd ansible
docker compose -f compose-dev.yaml build app
docker compose -f compose-dev.yaml run app bash
```

Install Ansible Controller dependencies:

```bash
ansible-galaxy install -r /usr/src/app/requirements.yml
```

Create an ssh key for the Ansible Controller:

```bash
ssh-keygen
```

Or use an existing private key in the Ansible Controller:

```bash
cp .ssh/id_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keygen -f ~/.ssh/id_rsa -y > ~/.ssh/id_rsa.pub
```

Copy the key to the hosts:

```bash
ssh-copy-id ubuntu@host-1
ssh-copy-id ubuntu@host-2
```

Verify that the hosts are reachable:

```bash
ansible -i hosts.ini -m ping all
```

Set static ip address for host-1

```bash
ssh host-1
sudo su

{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    eth1:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 192.168.0.2/24"
} > /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/01-netcfg.yaml
netplan apply
exit
```

Set static ip address for host-2

```bash
ssh host-1
sudo su

{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    eth1:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 192.168.0.3/24"
} > /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/01-netcfg.yaml
netplan apply
exit
```

Perform initial hosts setup:

```bash
ansible-playbook -i hosts.ini site.yml -t init -K
```

Complete host setup:

```bash
ansible-playbook -i hosts.ini site.yml
```

**Note:** VMs are deployed from a template that is expected to be located at
`./ansible/files/vm.qcow2`. In the case that this is not there, the following section explains how
to setup the VMs from an Ubuntu ISO.

## Manual VMs provisioning in Hosts

Transfer Ubuntu ISO for VM Provisioning

```bash
scp ./cloud-init/nfs/ubuntu-22.04.4-live-server-amd64.iso \
    ubuntu@host-1.mshome.net:/tmp/ubuntu-22.04.4-live-server-amd64.iso
scp ./cloud-init/nfs/ubuntu-22.04.4-live-server-amd64.iso \
    ubuntu@host-2.mshome.net:/tmp/ubuntu-22.04.4-live-server-amd64.iso
```

Install vm-1 in host-1

```bash
ssh host-1
sudo virt-install \
    --name vm-1 \
    --os-variant ubuntu22.04 \
    --vcpus 3 \
    --memory 2000 \
    --location /opt/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
    --network bridge=virbr0,model=virtio \
    --disk size=5 \
    --graphics none \
    --extra-args='console=ttyS0,115200n8 -- console=ttyS0,115200n8' \
    --debug
```

Install vm-2 in host-1

```bash
ssh host-1
sudo virt-install \
    --name vm-2 \
    --os-variant ubuntu22.04 \
    --vcpus 3 \
    --memory 2000 \
    --location /opt/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
    --network bridge=virbr0,model=virtio \
    --disk size=5 \
    --graphics none \
    --extra-args='console=ttyS0,115200n8 -- console=ttyS0,115200n8' \
    --debug
```

Install vm-3 in host-2

```bash
ssh host-1
sudo virt-install \
    --name vm-3 \
    --os-variant ubuntu22.04 \
    --vcpus 3 \
    --memory 2000 \
    --location /opt/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
    --network bridge=virbr0,model=virtio \
    --disk size=5 \
    --graphics none \
    --extra-args='console=ttyS0,115200n8 -- console=ttyS0,115200n8' \
    --debug
```

Install vm-4 in host-2

```bash
ssh host-1
sudo virt-install \
    --name vm-2 \
    --os-variant ubuntu22.04 \
    --vcpus 3 \
    --memory 2000 \
    --location /opt/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
    --network bridge=virbr0,model=virtio \
    --disk size=5 \
    --graphics none \
    --extra-args='console=ttyS0,115200n8 -- console=ttyS0,115200n8' \
    --debug
```

## Complete VMs configuration

### Configuration for vm-1

```bash
# SSH into the host
ssh host-1

# Open console to vm
sudo virsh console vm-1

# Elevate to root
sudo su

# Generate host keys for ssh
ssh-keygen -A

# Extend disk to all free space
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Set hostname
hostnamectl set-hostname vm-1

# Set static ip address
{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    enp1s0:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 10.10.10.10/24"
} > /etc/netplan/01-netcfg.yaml

# Fix permissions of netcfg
chmod 600 /etc/netplan/01-netcfg.yaml

# Apply
netplan apply
```

### Configuration for vm-2

```bash
# SSH into the host
ssh host-1

# Open console to vm
sudo virsh console vm-2

# Elevate to root
sudo su

# Generate host keys for ssh
ssh-keygen -A

# Extend disk to all free space
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Set hostname
hostnamectl set-hostname vm-1

# Set static ip address
{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    enp1s0:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 10.10.10.20/24"
} > /etc/netplan/01-netcfg.yaml

# Fix permissions of netcfg
chmod 600 /etc/netplan/01-netcfg.yaml

# Apply
netplan apply
```

### Configuration for vm-3

```bash
# SSH into the host
ssh host-2

# Open console to vm
sudo virsh console vm-3

# Elevate to root
sudo su

# Generate host keys for ssh
ssh-keygen -A

# Extend disk to all free space
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Set hostname
hostnamectl set-hostname vm-1

# Set static ip address
{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    enp1s0:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 10.10.10.30/24"
} > /etc/netplan/01-netcfg.yaml

# Fix permissions of netcfg
chmod 600 /etc/netplan/01-netcfg.yaml

# Apply
netplan apply
```

### Configuration for vm-4

```bash
# SSH into the host
ssh host-2

# Open console to vm
sudo virsh console vm-4

# Elevate to root
sudo su

# Generate host keys for ssh
ssh-keygen -A

# Extend disk to all free space
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Set hostname
hostnamectl set-hostname vm-1

# Set static ip address
{
    echo "network:"
    echo "  version: 2"
    echo "  renderer: networkd"
    echo "  ethernets:"
    echo "    enp1s0:"
    echo "      dhcp4: no"
    echo "      addresses:"
    echo "        - 10.10.10.40/24"
} > /etc/netplan/01-netcfg.yaml

# Fix permissions of netcfg
chmod 600 /etc/netplan/01-netcfg.yaml

# Apply
netplan apply
```

## Tests the VMs

The tools required on the vms to run network tests the following:

```bash
apt update && apt install inetutils-ping iperf3 net-tools nano
```

Check the state of the virtual switch

```bash
ovs-vsctl show
```

Output will be something like:

```text
b6e1b292-6f1d-4ab3-bf1a-006e96a5fae9
    Bridge ovsbr
        Port gre0
            Interface gre0
                type: gre
                options: {remote_ip="192.168.0.3"}
        Port ovsbr
            Interface ovsbr
                type: internal
        Port vnet0
            Interface vnet0
        Port vnet1
            Interface vnet1
    ovs_version: "2.17.8"
```

Get the vnet of an specific vm:

```bash
virsh dumpxml vm-1 | grep vnet
```

Apply a vlan tag to the vnet:

```
ovs-vsctl set port vnet1 tag=100
```

Run ping connectivity test:

```bash
ping 10.10.10.10
```

Run iperf3 bandwidth test:

```bash
# In the server:
sudo iperf3 -s

# In the client, tcp test:
sudo iperf3 -c 10.10.10.10 -P 2 -t 10 -b 1G

# In the client, udp test:
sudo iperf3 -c 10.10.10.10 -P 2 -t 10 -b 1G -u
```

## Destroy the hosts

```ps1
.\scripts\destroy-vm.ps1 -vm "host-1"
.\scripts\destroy-vm.ps1 -vm "host-2"
```
