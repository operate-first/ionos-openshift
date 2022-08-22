output "control" {
  description = "ID of the node"
  value       = ionoscloud_server.control.*.id
}
output "compute" {
  description = "ID of the node"
  value       = ionoscloud_server.compute.*.id
}
