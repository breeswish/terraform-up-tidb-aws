locals {

    cloudinit_merge_type = "list(append)+dict(no_replace,recurse_list)+str()"

    userdata_add_alternative_ssh_public = <<-EOT
    #!/bin/bash
    echo '${trimspace(file(local.alternative_ssh_public))}' | tee -a /home/${local.username}/.ssh/authorized_keys
    EOT

    userdata_haproxy_cfg = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username}/haproxy.cfg"
            permissions = "0644"
            owner       = "${local.username}:${local.username}"
            encoding    = "b64"
            content     = base64encode(templatefile("./files/haproxy.cfg.tftpl", {
                tidb_hosts = local.tidb_private_ips,
            }))
        }]
    })}
    EOT

    userdata_topology_yaml = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username}/topology.yaml"
            permissions = "0644"
            owner       = "${local.username}:${local.username}"
            encoding    = "b64"
            content     = base64encode(templatefile("./files/topology.yaml.tftpl", {
                tidb_hosts = local.tidb_private_ips,
                tikv_hosts = local.tikv_private_ips,
                tiflash_hosts = local.tiflash_private_ips,
                s3_region = local.region,
            }))
        }]
    })}
    EOT

    userdata_master_ssh_pairs = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username}/.ssh/id_rsa"
            permissions = "0400"
            owner       = "${local.username}:${local.username}"
            encoding    = "b64"
            content     = base64encode(file(local.master_ssh_key))
        }, {
            path        = "/home/${local.username}/.ssh/id_rsa.pub"
            permissions = "0644"
            owner       = "${local.username}:${local.username}"
            encoding    = "b64"
            content     = base64encode(file(local.master_ssh_public))
        }]
    })}
    EOT

}

# For all servers except for center server, use the following cloudinit config.
data "cloudinit_config" "common_server" {
    gzip          = true
    base64_encode = true

    part {
        content_type = "text/x-shellscript"
        filename     = "add_ssh.sh"
        content      = local.userdata_add_alternative_ssh_public
    }
}

# For center server, use the following cloudinit config.
data "cloudinit_config" "center_server" {
    gzip          = true
    base64_encode = true

    part {
        content_type = "text/cloud-config"
        filename     = "write_haproxy.cfg"
        content      = local.userdata_haproxy_cfg
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/cloud-config"
        filename     = "write_topology.cfg"
        content      = local.userdata_topology_yaml
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/cloud-config"
        filename     = "write_master_ssh_pairs.cfg"
        content      = local.userdata_master_ssh_pairs
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/x-shellscript"
        filename     = "add_ssh.sh"
        content      = local.userdata_add_alternative_ssh_public
    }

    part {
        content_type = "text/x-shellscript"
        filename     = "cloudinit_center.sh"
        content      = file("./files/cloudinit_center.sh")
    }

}
