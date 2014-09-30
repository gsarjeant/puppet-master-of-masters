class role::puppet::master {
  include profile::puppet::master
  include profile::puppet::ca
}
