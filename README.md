## deploy

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

above commands deploys 2 compute engines.
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
