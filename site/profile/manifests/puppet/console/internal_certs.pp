# Profile: puppet::console::internal_certs
#
# This is used to ship the pe-internal-dashboard certificates from the CA to the PE console.
# It will initially be used for a single agent run against the MoM CA directly,
# but I may extend it to pull the certs down to the tenant compile master, and
# manage them from there
#
# NOTE: The internal certs must be manually copied from the MoM console to
#       /opt/puppet/share/puppet-dashboard/certs for a split MoM installation.
# NOTE: We don't generally encourage parameters in profiles, but I can't think
#       of a better way to handle the fact that these certs need to be owned by
#       different users on different nodes.
class profile::puppet::console::internal_certs(
  $console_cert_owner = 'puppet-dashboard',
  $console_cert_group = 'puppet-dashboard',
){

  include profile::params

  File {
    owner => $console_cert_owner,
    group => $console_cert_group,
    mode  => '0755',
  }

  file { "${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem":
    ensure  => file,
    content => file("${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem"),
  }
  file { "${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.private_key.pem":
    ensure  => file,
    content => file("${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.private_key.pem"),
    mode    => '0440',
  }
  file { "${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.ca_crl.pem":
    ensure  => file,
    content => file("${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.ca_crl.pem"),
  }
  file { "${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.public_key.pem":
    ensure  => file,
    content => file("${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.public_key.pem"),
  }
  file { "${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.cert.pem":
    ensure  => file,
    content => file("${::profile::params::pe_console_internal_cert_dir}/pe-internal-dashboard.cert.pem"),
  }
}
