# Profile: puppet::console::internal_certs
#
# This is used to ship the pe-internal-dashboard certificates from the CA to the PE console.
# It will initially be used for a single agent run against the MoM CA directly,
# but I may extend it to pull the certs down to the tenant compile master, and
# manage them from there
#
# NOTE: The internal certs must be manually copied from the MoM console to
#       /opt/puppet/share/puppet-dashboard/certs for a split MoM installation.
class profile::puppet::console::internal_certs(){
  $console_internal_cert_dir = '/opt/puppet/share/puppet-dashboard/certs'

  file { "${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem":
    ensure => file,
    content => file("${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem")
  }
  file { "${console_internal_cert_dir}/pe-internal-dashboard.private_key.pem":
    ensure => file,
    content => file("${console_internal_cert_dir}/pe-internal-dashboard.private_key.pem")
  }
  file { "${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem":
    ensure => file,
    content => file("${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem")
  }
  file { "${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem":
    ensure => file,
    content => file("${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem")
  }
  file { "${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem":
    ensure => file,
    content => file("${console_internal_cert_dir}/pe-internal-dashboard.ca_cert.pem")
  }
}
