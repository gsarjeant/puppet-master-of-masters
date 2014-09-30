class profile::params {
  #############################################################################
  ## For the MoM servers
  #############################################################################
  # Domains for MoM servers and tenant PE servers
  # NOTE: May not need this - all tenants may be in the same domain as the MoM servers
  $pe_mom_domain                      = 'example.vm'
  $pe_tenant_domain                   = $::domain

  $pe_mom_ca_hostname                 = 'pe-master'
  $pe_mom_ca_fqdn                     = "${pe_puppetca_hostname}.${pe_mom_domain}"

  $pe_mom_console_hostname            = 'pe-console'
  $pe_mom_console_fqdn                = "${pe_puppetconsole_hostname}.${pe_mom_domain}"

  $pe_mom_puppetdb_hostname           = 'pe-puppetdb'
  $pe_puppetdb_fqdn                   = "${pe_puppetdb_hostname}.${pe_mom_domain}"

  $pe_mom_master_hostname             = 'pe-master'
  $pe_mom_master_fqdn                 = "${pe_puppetmaster_hostname}.${pe_mom_domain}"

  $pe_mom_consolepg_hostname          = $pe_mom_puppetdb_hostname
  $pe_mom_consolepg_fqdn              = "${pe_puppetconsolepg_hostname}.${pe_mom_domain}"

  $pe_mom_puppetdbpg_hostname         = $pe_mom_puppetdb_hostname
  $pe_mom_puppetdbpg_fqdn             = "${pe_mom_puppetdbpg_hostname}.${pe_mom_domain}"

  $pe_puppetconsole_pgdb_password     = 'hunter2'
  $pe_puppetconsoleauth_pgdb_password = 'hunter2'
  $pe_puppetdb_pgdb_password          = 'hunter2'
  $pe_console_certname                = 'pe-internal-dashboard'

  ## PuppetDB Whitelist
  $pe_puppetdb_whitelist = [
    $::clientcert,
    $pe_console_certname,
    $pe_puppetca_fqdn,
  ]

  ## Console authorizations
  $pe_console_authorizations = {
    'pe-internal-dashboard' => {
      'role'                => 'read-write'
    },
    "${::clientcert}"       => {
      'role'                => 'read-write'
    },
    "${pe_puppetca_fqdn}" => {
      'role'                => 'read-write'
    },
  }

  ## Mcollective
  $pe_stomp_servers = [
    $pe_puppetca_fqdn,
  ]

  $pe_activemq_brokers = [
    $pe_mom_ca_fqdn,
    "puppetmaster.${pe_tenant_domain}",
  ]

  $control_repo_address = 'https://github.com/gsarjeant/puppet-master-of-masters'
  #############################################################################
}
