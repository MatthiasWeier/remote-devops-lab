variable "tenancy_ocid" {
  description = "The OCID of your Oracle Account"
  type        = string
}

variable "subnet_ocid" {
  description = "The OCID of your VCN Subnet"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "C:/Users/Matthias/.ssh/oracle-docker-2026-04-26.key.pub"
}

variable "instance_name" {
  description = "Name of the server in the Oracle Dashboard"
  type        = string
  default     = "Terraform-Sandbox-Server"
}

variable "instance_shape" {
  description = "The shape of the instance (e.g., VM.Standard.E5.Flex)"
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "instance_cpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 1
}

variable "instance_ram" {
  description = "Amount of RAM in GB"
  type        = number
  default     = 4
}

variable "os_version" {
  description = "Ubuntu Version (e.g., 22.04 or 24.04)"
  type        = string
  default     = "22.04"
}

variable "cloud_init_script" {
  description = "Path to the bash script to run on first boot"
  type        = string
  default     = "scripts/setup.sh"
}