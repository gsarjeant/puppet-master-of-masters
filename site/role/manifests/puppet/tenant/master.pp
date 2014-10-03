class role::puppet::tenant::master {
  include profile::puppet::master
  include profile::puppet::ca
  include profile::puppet::console::internal_certs
}
