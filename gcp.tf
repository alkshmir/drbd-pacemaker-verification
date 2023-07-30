provider "google" {
  project = "gke-test-375507"
  region  = "us-central1"  # You can adjust this region as needed (Iowa is in us-central1)
}

resource "google_compute_network" "vpc_network" {
  name = "my-custom-mode-network"
  auto_create_subnetworks = false
  mtu  = 1460 
}

resource "google_compute_subnetwork" "default" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_instance" "vm_instance" {
  count        = 2
  name         = "compute-instance-${count.index + 1}"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"  # Replace with your desired zone in Iowa
  tags         = ["ssh", "internal"]

  scheduling {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      size  = 10
      type  = "pd-standard"
      image = "debian-cloud/debian-11"
    }
  }

  # install ansible
  # metadata_startup_script = "sudo wget -O /usr/share/keyrings/ansible.asc 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367'; sudo sh -c \"echo 'deb [signed-by=/usr/share/keyrings/ansible.asc] http://ppa.launchpad.net/ansible/ansible/ubuntu focal main' > /etc/apt/sources.list.d/ansible.list\"; sudo apt-get update; sudo apt-get install -y ansible git;"
  # permit root login
  metadata_startup_script = "sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config; sudo systemctl restart sshd"

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
    access_config {
      // Ephemeral IP will be assigned by default
    }
  }
  metadata = {
    ssh-keys = "root:${var.ssh_public_key}"
  }
}

resource "google_compute_disk" "os_disk" {
  count       = 2
  name        = "os-disk-${count.index + 1}"
  size        = 10
  type        = "pd-standard"
  zone        = "us-central1-a"  # Replace with your desired zone in Iowa
}

# Attach the OS disks to the VM instances
resource "google_compute_attached_disk" "os_disk_attachment" {
  count       = 2
  instance    = google_compute_instance.vm_instance[count.index].name
  disk        = google_compute_disk.os_disk[count.index].name
  zone        = "us-central1-a"
}

# Additional 10GB zonal standard persistent volumes
resource "google_compute_disk" "additional_disk" {
  count       = 2
  name        = "additional-disk-${count.index + 1}"
  size        = 10
  type        = "pd-standard"
  zone        = "us-central1-a"  # Replace with your desired zone in Iowa
}

# Attach the additional disks to the VM instances
resource "google_compute_attached_disk" "additional_disk_attachment" {
  count       = 2
  instance    = google_compute_instance.vm_instance[count.index].name
  disk        = google_compute_disk.additional_disk[count.index].name
  zone        = "us-central1-a"
}

# Firewall rule that allows SSH from Cloud IAP
# for more info: https://cloud.google.com/iap/docs/using-tcp-forwarding
resource "google_compute_firewall" "ssh" {
  name = "allow-ssh-from-iap"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# Firewall rule that allows any communication between VMs
resource "google_compute_firewall" "internal" {
  name = "allow-internal"
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  network       = google_compute_network.vpc_network.id
  priority      = 1200
  source_ranges = [google_compute_subnetwork.default.ip_cidr_range]
  target_tags   = ["internal"]
}

