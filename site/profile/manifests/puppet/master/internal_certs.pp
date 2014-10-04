# Class: profile::puppet::master::internal_certs
#
# Manages the pe-mcollective internal certs on the puppet master
#
# This is used primarily to ship the certs from a master-of-masters,
# so that they are moved correctly to a subordinate master
class profile::puppet::master::internal_certs{
  include profile::params

  File {
    owner => $profile::params::pe_master_owner,
    group => $profile::params::pe_master_group,
    mode  => 0644
  }

  # pe-mcollective certificates
  file { "${::profile::params::pe_master_ssl_cert_dir}/pe-internal-broker.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_cert_dir}/pe-internal-broker.pem"),
  }
  file { "${::profile::params::pe_master_ssl_cert_dir}/pe-internal-mcollective-servers.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_cert_dir}/pe-internal-mcollective-servers.pem"),
  }
  file { "${::profile::params::pe_master_ssl_cert_dir}/pe-internal-peadmin-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_cert_dir}/pe-internal-peadmin-mcollective-client.pem"),
  }
  file { "${::profile::params::pe_master_ssl_cert_dir}/pe-internal-puppet-console-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_cert_dir}/pe-internal-puppet-console-mcollective-client.pem"),
  }

  # pe-mcollective public keys
  file { "${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-broker.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-broker.pem"),
  }
  file { "${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-mcollective-servers.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-mcollective-servers.pem"),
  }
  file { "${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-peadmin-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-peadmin-mcollective-client.pem"),
  }
  file { "${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-puppet-console-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_public_key_dir}/pe-internal-puppet-console-mcollective-client.pem"),
  }

  # pe-mcollective private keys
  file { "${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-broker.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-broker.pem"),
  }
  file { "${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-mcollective-servers.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-mcollective-servers.pem"),
  }
  file { "${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-peadmin-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-peadmin-mcollective-client.pem"),
  }
  file { "${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-puppet-console-mcollective-client.pem":
    ensure  => file,
    content => file("${::profile::params::pe_master_ssl_private_key_dir}/pe-internal-puppet-console-mcollective-client.pem"),
  }

}
