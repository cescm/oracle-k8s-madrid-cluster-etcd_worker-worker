resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.instance_display_name}-vcn"
  cidr_block     = "10.0.0.0/16"
}
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.instance_display_name}-igw"
  is_enabled     = true
}
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}
resource "oci_core_security_list" "sec_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.instance_display_name}-sec-list"
  egress_security_rules { protocol = "all" destination = "0.0.0.0/0" }
  ingress_security_rules { protocol = "6" source = var.allowed_ssh_cidr tcp_options { min = 22 max = 22 } }
  ingress_security_rules { protocol = "6" source = var.allowed_k8s_api_cidr tcp_options { min = 6443 max = 6443 } }
  ingress_security_rules { protocol = "6" source = var.allowed_nodeport_cidr tcp_options { min = 30000 max = 32767 } }
  ingress_security_rules { protocol = "6" source = "0.0.0.0/0" tcp_options { min = 10250 max = 10250 } }
  ingress_security_rules { protocol = "17" source = var.allowed_wireguard_cidr udp_options { min = 51820 max = 51820 } }
}
resource "oci_core_subnet" "subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  availability_domain        = var.availability_domain
  display_name               = "${var.instance_display_name}-subnet"
  cidr_block                 = var.subnet_cidr
  route_table_id             = oci_core_route_table.route_table.id
  security_list_ids          = [oci_core_security_list.sec_list.id]
  prohibit_public_ip_on_vnic = false
}
resource "oci_core_instance" "node" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = var.instance_display_name
  shape               = var.instance_shape
  create_vnic_details { subnet_id = oci_core_subnet.subnet.id assign_public_ip = true }
  source_details { source_type = "image" image_id = var.instance_image_ocid }
  metadata = {
    user_data = templatefile("${path.module}/cloudinit.yaml.tpl", {
      ssh_public_key     = var.ssh_authorized_key
      overlay_private_ip = var.overlay_private_ip
    })
  }
}
resource "oci_core_volume" "bv" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "${var.instance_display_name}-block-volume"
  size_in_gbs         = var.block_volume_size_gb
}
resource "oci_core_volume_attachment" "attach" {
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.node.id
  volume_id      = oci_core_volume.bv.id
  display_name   = "${var.instance_display_name}-attach"
  type           = "iscsi"
}
