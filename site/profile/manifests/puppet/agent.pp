class profile::puppet::agent {

  include profile::params

  ## Use the pe_server module to manage some common Puppet settings
  class { 'pe_server':
    is_master                    => false,
    ca_server                    => $profile::params::pe_mom_ca_fqdn,
    change_filebucket            => true,
    filebucket_server            => $profile::params::pe_tenant_master_fqdn,
    export_puppetdb_whitelist    => false,
    export_console_authorization => false,
  }

  augeas { 'puppet.conf_agent_environment':
    context => '/files/etc/puppetlabs/puppet/puppet.conf',
    changes => "set agent/environment ${::agent_environment}",
  }

}
