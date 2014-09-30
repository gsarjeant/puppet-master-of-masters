class profile::puppet::agent {

  include profile::params

  ## Use the pe_server module to manage some common Puppet settings
  class { 'pe_server':
    is_master                    => false,
    ca_server                    => $profile::params::pe_puppetca_fqdn,
    change_filebucket            => true,
    filebucket_server            => $profile::params::pe_puppetmaster_fqdn,
    export_puppetdb_whitelist    => false,
    export_console_authorization => false,
  }

  ## Ensure the "server" points to our generic CNAME
  augeas { 'puppet.conf_server':
    context => '/files/etc/puppetlabs/puppet/puppet.conf',
    changes => "set main/server ${profiles::params::pe_puppetmaster_fqdn}",
  }

}
