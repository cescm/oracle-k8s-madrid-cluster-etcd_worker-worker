variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_id" {}
variable "availability_domain" {}
variable "ssh_authorized_key" {}
variable "instance_image_ocid" {}
variable "instance_shape" { default = "VM.Standard.A1.Flex" }
variable "instance_display_name" {}
variable "subnet_cidr" {}
variable "block_volume_size_gb" { default = 200 }
variable "overlay_private_ip" { default = "" }
variable "allowed_ssh_cidr" { default = "0.0.0.0/0" }
variable "allowed_k8s_api_cidr" { default = "0.0.0.0/0" }
variable "allowed_nodeport_cidr" { default = "0.0.0.0/0" }
