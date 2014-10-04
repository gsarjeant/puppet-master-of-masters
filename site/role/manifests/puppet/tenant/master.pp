class role::puppet::tenant::master {
  include profile::puppet::master
  include profile::puppet::master::internal_certs
  include profile::puppet::ca

  # Copy the pe-internal console certs to the tenant master so that it can manage them for the tenant console
  # NOTE: The certs must be owned by pe-puppet so that the tenant puppet master can read the private key
  class { 'profile::puppet::console::internal_certs':
    console_cert_owner => 'pe-puppet',
    console_cert_group => 'pe-puppet',
  }
}
