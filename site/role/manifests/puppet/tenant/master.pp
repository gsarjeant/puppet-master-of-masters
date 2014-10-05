class role::puppet::tenant::master {
  include profile::puppet::master
  include profile::puppet::ca
}
