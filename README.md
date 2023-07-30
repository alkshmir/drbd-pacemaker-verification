## deploy

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

### install packages using ansible
install required packages using ansible preinstalled on each VM.

specify internal IPs of VMs (run on terraform node)
```
jq '.resources[] | select(.type == "google_compute_instance") | .instances[].attributes.network_interface[].network_ip' terraform.tfstate -r
```

ssh to one of the provisioned nodes.
clone this repository (on one node)
```
git clone https://github.com/alkshmir/drbd-pacemaker-verification.git
```

setup inventory
```
cd drbd-pacemaker-verification
cat << EOF > inventory.ini
> 10.0.1.2
> 10.0.1.3
> EOF
```
* replace IP addresses above with the values specified by `jq` command above (or values shown on Google cloud console)


