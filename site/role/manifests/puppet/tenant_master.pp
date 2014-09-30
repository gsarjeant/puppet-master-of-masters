class role::puppet::tenant_master {
  include profile::puppet::master
  include profile::puppet::ca
}
