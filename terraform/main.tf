data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.os_version
  shape                    = var.instance_shape
}

resource "oci_core_instance" "terraform_test" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.tenancy_ocid
  display_name        = var.instance_name
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_cpus
    memory_in_gbs = var.instance_ram
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

output "instance_ip" {
  value = oci_core_instance.terraform_test.public_ip
}