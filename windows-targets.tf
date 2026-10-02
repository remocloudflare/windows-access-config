# Windows RDP target model. The name-to-IP inventory is loaded from files/ips;
# variables live in variables.tf.
locals {
  windows_target_ips = jsondecode(file("${path.module}/${var.windows_target_ips_file}"))

  rdp_servers = {
    for key, ipv4 in local.windows_target_ips : key => {
      hostname           = "rdp-${replace(key, "_", "-")}"
      ipv4               = ipv4
      virtual_network_id = lookup(var.windows_target_virtual_network_ids, key, var.default_windows_target_virtual_network_id)
      access_profile     = lookup(var.windows_target_access_profiles, key, var.default_windows_target_access_profile)
      tags               = merge(var.default_windows_target_tags, lookup(var.windows_target_tags, key, {}))
    }
  }

  invalid_rdp_servers = {
    for key, server in local.rdp_servers : key => server
    if !can(cidrhost("${server.ipv4}/32", 0)) || !contains(keys(var.rdp_access_profiles), server.access_profile)
  }
}
