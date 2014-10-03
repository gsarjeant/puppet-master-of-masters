##
## Profile for PuppetDB/PostgreSQL hosts
##
class profile::puppet::puppetdb {

  include profile::params

  class { 'pe_server':
    ca_server                    => $profile::params::pe_mom_ca_fqdn,
    export_puppetdb_whitelist    => false,
    export_console_authorization => false,
  }

  class { 'pe_server::puppetdb':
    manage_postgres => false,
  }

  ## Explicitly define whitelisted certificates
  pe_server::puppetdb::whitelist { $profile::params::pe_tenant_puppetdb_whitelist: }

}
