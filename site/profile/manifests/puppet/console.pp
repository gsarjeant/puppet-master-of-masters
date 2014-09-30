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
  $create_console_certs = $::clientcert ? {
    $profile::params::pe_puppetconsole01_fqdn => true,
    default                                   => false,
  }

  ## Configure the filebucket
  ## Also disable whitelist exporting, since we can't collect them durig
  ## bootstrapping anyway.
  class { 'pe_server':
    ca_server                    => $profile::params::pe_puppetca_fqdn,
    filebucket_server            => $profile::params::pe_puppetmaster_fqdn,
    export_puppetdb_whitelist    => false,
    export_console_authorization => false,
  }

  ## The console system is installed as a full-stack master.
  ## That said, we need to disable its CA functionality.
  class { 'pe_server::ca':
    active_ca => false,
  }

  ## Configure the console(s) accordingly.
  ## Don't retrieve the console certs from the CA, create them on the primary,
  ## and don't collected exported whitelist entries.
  class { 'pe_server::console':
    ca_server                      => $profile::params::pe_puppetca_fqdn,
    inventory_server               => $profile::params::pe_puppetmaster_fqdn,
    console_cert_name              => $profile::params::pe_console_certname,
    console_certs_from_ca          => false,
    create_console_certs           => $create_console_certs,
    collect_exported_authorization => false,
  }

  ## Configure the console's database connection
  class { 'pe_server::console::database':
    password              => $profile::params::pe_puppetconsole_pgdb_password,
    console_auth_password => $profile::params::pe_puppetconsoleauth_pgdb_password,
    host                  => $profile::params::pe_puppetconsolepg_fqdn,
  }

  ## We need to manage PostgreSQL with the PuppetDB class, since that's how
  ## PE does it.
  class { 'pe_server::puppetdb':
    puppetdb_ssl_setup     => false,
    postgres_database_host => $profile::params::pe_puppetconsolepg_fqdn,
  }

  ## Add some console authorizations
  class { 'pe_server::console::authorization':
    authorizations            => $profile::params::pe_console_authorizations,
  }

  ## Disable the PuppetDB service
  ## This is already being managed by a PE class, so we use a collector
  ## to override attributes so we can disable it on the console.
  Service <| title == 'pe-puppetdb' |> {
    ensure => 'stopped',
    enable => false,
  }

  ## Disable the pe-activemq service
  ## This is the job of the primary master
  service { 'pe-activemq':
    ensure => 'stopped',
    enable => false,
  }

  service { 'pe-httpd':
    ensure => 'running',
  }
}
