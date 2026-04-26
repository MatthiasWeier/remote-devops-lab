data "oci_identity_availability_domains" "ads" {
  # OLD: compartment_id = "ocid1.tenancy.oc1..aaaaaaa..."
  # NEW: We point it to the variable bucket! No quotation marks!
  compartment_id = var.tenancy_ocid
}