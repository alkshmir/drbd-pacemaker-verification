# drbd-pacemaker-verification
Provision replicated block storage with DRBD and PostgreSQL on top of that managed by pacemaker cluster.
VM provisioning by terraform ( tested on Google Cloud ) and installation of middleware by Ansible.

## deploy
Before deploying resources you need to install following tools:
- `gcloud`
- `terraform`
- `ansible`
- `jq`

### configure ssh keys
make ssh key pair to connect VMs.
```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

make `terraform.tfvars` file:
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your_email@example.com"
```
* Replace `"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your_email@example.com"` with the actual content of your public key.

### provisioning VMs
```
gcloud init
gcloud auth application-default login
```
replace project id on `gcp.tf`
```
terraform init
terraform plan
terraform apply
```

above commands deploys 2 debian compute engines.
### configure ssh connections

specify ephemeral external IPs of VMs (run on terraform node)
```
jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].access_config[].nat_ip' terraform.tfstate -r
```

setup ssh configuration in `~/.ssh/config`
```
Host compute-instance-1
    HostName aaa.bbb.ccc.ddd
    User root
    IdentityFile /path/to/secret_key
Host compute-instance-2
    HostName aaa.bbb.ccc.ddd
    User root
    IdentityFile /path/to/secret_key
```
* replace IP addresses above with the values specified by `jq` command above (or values shown on Google cloud console)

type `ssh compute-instace-1` and `ssh compute-instance-2` to check configuration and add host keys to `known_hosts`.

### install packages using ansible

specify internal IPs of VMs IPs
```
jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].network_ip' terraform.tfstate -r
```

setup inventory
```
cp inventory_sample.yaml inventory.yaml
vim inventory.yaml
```
* replace `internal_ip` with the values specified by `jq` command above (or values shown on Google cloud console)


run installation
```
ansible-playbook -i inventory.yaml install.yaml
```

### Desired state of pacemaker
```
$ pcs status
Cluster name: mycluster
Cluster Summary:
  * Stack: corosync
  * Current DC: compute-instance-1 (version 2.0.5-ba59be7122) - partition with quorum
  * Last updated: Thu Aug  3 15:02:26 2023
  * Last change:  Thu Aug  3 15:01:08 2023 by root via cibadmin on compute-instance-1
  * 2 nodes configured
  * 4 resource instances configured

Node List:
  * Online: [ compute-instance-1 compute-instance-2 ]

Full List of Resources:
  * Clone Set: ms_drbd_r0 [drbd_r0] (promotable):
    * Masters: [ compute-instance-1 ]
    * Slaves: [ compute-instance-2 ]
  * Resource Group: postgres:
    * fs_drbd1  (ocf::heartbeat:Filesystem):     Started compute-instance-1
    * postgresql        (ocf::heartbeat:pgsql):  Started compute-instance-1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```
