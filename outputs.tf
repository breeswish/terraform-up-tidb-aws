output "ssh-center" {
  value = "ssh ${local.username}@${aws_instance.center.public_ip}"
}

output "url-tidb-dashboard" {
  value = "http://${aws_instance.pd.public_ip}:2379/dashboard"
}

output "url-grafana" {
  value = "http://${aws_instance.pd.public_ip}:3000"
}

output "private-ip-tidb" {
  value = local.tidb_private_ips
}

output "private-ip-tikv" {
  value = local.tikv_private_ips
}

output "private-ip-tiflash" {
  value = local.tiflash_private_ips
}

output "private-ip-pd" {
  value = local.pd_private_ip
}
