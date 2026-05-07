# ---------------------------------------------------------------------------------------------------------------------
# This file defines the output values of the root configuration.
# These values can be displayed after applying the Terraform configuration and referenced by other configurations.
# ---------------------------------------------------------------------------------------------------------------------

# Output the IP address of the created web server VM
output "webserver_ip_address" {
  description = "The IP address of the Ubuntu Webserver"
  value       = module.ubuntu_webserver.ip_address
}

# Output the VM ID of the created web server VM
output "webserver_vmid" {
  description = "The VM ID of the Ubuntu Webserver"
  value       = module.ubuntu_webserver.vmid
}

# Add more outputs here, e.g., for other VMs
/*
output "dbserver_ip_address" {
  description = "The IP address of the Ubuntu DB Server"
  value       = module.ubuntu_dbserver.ip_address
}
*/
