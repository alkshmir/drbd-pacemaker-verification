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


