## This class needs to:
##   - Disable the CA and master functionality on this server
##   - Manage the console's whitelist
##   - Manage the console's database config
##   - Configure PostgreSQL to listen on all interfaces
##   - Configure PuppetDB to use the primary PostgreSQL database
class profile::puppet::console {

  include profile::params

  ## We only want the 'primary' console to create the certificates.
  ## Additional consoles will need to obtain their certificates from the
  ## primary console.
  ## NOTE: GS - I think this is geared more toward's Josh's setup - need to investigate
  $create_console_certs = $::clientcert ? {
    $profile::params::pe_mom_console_fqdn => true,
    default                               => false,
  }

  ## Configure the filebucket
  ## Also disable whitelist exporting, since we can't collect them durig
  ## bootstrapping anyway.
  class { 'pe_server':
    ca_server                    => $profile::params::pe_mom_ca_fqdn,
    filebucket_server            => $profile::params::pe_tenant_master_fqdn,
    export_puppetdb_whitelist    => false,
    export_console_authorization => false,
  }

  ## Configure the console(s) accordingly.
  ## Don't retrieve the console certs from the CA, create them on the primary,
  ## and don't collect exported whitelist entries.
  class { 'pe_server::console':
    ca_server                      => $profile::params::pe_mom_ca_fqdn,
    inventory_server               => $profile::params::pe_tenant_master_fqdn,
    console_cert_name              => $profile::params::pe_console_certname,
    puppetdb_host                  => $profile::params::pe_tenant_puppetdb_hostname,
    console_certs_from_ca          => false,
    create_console_certs           => false,
    collect_exported_authorization => false,
  }

  ## Configure the console's database connection
  class { 'pe_server::console::database':
    password              => $profile::params::pe_tenant_console_pgdb_password,
    console_auth_password => $profile::params::pe_tenant_consoleauth_pgdb_password,
    host                  => $profile::params::pe_tenant_consolepg_fqdn,
  }

  ## Add some console authorizations
  class { 'pe_server::console::authorization':
    authorizations            => $profile::params::pe_tenant_console_authorizations,
  }

  ## Disable the pe-activemq service
  ## This is the job of the primary master
#  service { 'pe-activemq':
#    ensure => 'stopped',
#    enable => false,
#  }

  service { 'pe-httpd':
    ensure => 'running',
  }
}
