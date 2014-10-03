class role::puppet::tenant::master {
  include profile::puppet::master
  include profile::puppet::ca
  include profile::puppet::tenant::console::internal_certs
}
