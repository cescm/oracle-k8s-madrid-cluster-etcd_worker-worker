output "instance_public_ip" { value = oci_core_instance.node.public_ip }
output "instance_private_ip" { value = oci_core_instance.node.private_ip }
output "instance_id" { value = oci_core_instance.node.id }
output "block_volume_id" { value = oci_core_volume.bv.id }
