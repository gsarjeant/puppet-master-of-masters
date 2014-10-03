class role::puppet::tenant::console {
  include ::profile::puppet::console
  include ::profile::puppet::console::internal_certs

  Class['::profile::puppet::console'] -> Class['profile::puppet::console::internal_certs']
}
