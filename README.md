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

Create the hosts in Microsoft Hyper-V

```ps1
.\scripts\create-vm.ps1 -vm "host-1" `
    -image "$pwd\cloud-init\nfs\ubuntu-22.04.4-live-server-amd64.iso" `
    -seed "$pwd\cloud-init\nfs\seed-1.iso"
.\scripts\create-vm.ps1 `
    -vm "host-2" `
    -image "$pwd\cloud-init\nfs\ubuntu-22.04.4-live-server-amd64.iso" `
    -seed "$pwd\cloud-init\nfs\seed-2.iso"
```

Create the Ansible Controller:

```bash
cd ansible
docker compose -f compose-dev.yaml build app
docker compose -f compose-dev.yaml run app bash
```

Initial hosts setup:

```bash
ssh-keygen
ssh-copy-id ubuntu@host-1
ssh-copy-id ubuntu@host-2
ansible -i hosts.ini -m ping all
ansible-playbook -i hosts.ini site.yml -t init -K
```

Complete host setup:

```bash
ansible-playbook -i hosts.ini site.yml
```

Destroy the hosts:

```ps1
.\scripts\destroy-vm.ps1 -vm "host-1"
.\scripts\destroy-vm.ps1 -vm "host-2"
```