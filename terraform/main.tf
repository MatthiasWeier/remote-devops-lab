# 1. Fetch the latest Ubuntu 22.04 image from Oracle
data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E5.Flex"
}

# 2. Create the Sandbox Instance
resource "oci_core_instance" "terraform_test" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.tenancy_ocid
  display_name        = "Terraform-Sandbox-Server"
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  create_vnic_details {    
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {   
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# 3. Output the public IP address after creation
output "instance_ip" {
  value = oci_core_instance.terraform_test.public_ip
}