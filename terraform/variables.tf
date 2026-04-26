variable "tenancy_ocid" {
  description = "OCID of your Oracle Account"
  type        = string
}

variable "subnet_ocid" {
  description = "OCID of your VCN subnet"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "C:/Users/Matthias/.ssh/oracle-docker-2026-04-26.key.pub"
}