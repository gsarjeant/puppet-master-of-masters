class profile::params {
  #############################################################################
  ## Global
  #############################################################################
  $pe_console_certname                = 'pe-internal-dashboard'

  $pe_mom_ca_hostname                 = 'pe-master'
  $pe_mom_domain                      = 'example.vm'
  $pe_mom_ca_fqdn                     = "${pe_mom_ca_hostname}.${pe_mom_domain}"
  $pe_tenant_domain                   = 'tenant.example.vm'

  $pe_activemq_brokers = [
    $pe_mom_ca_fqdn,
    "pe-master.${pe_tenant_domain}",
  ]

  $pe_master_ssl_dir                  = '/etc/puppetlabs/puppet/ssl'
  $pe_master_ssl_cert_dir             = "${pe_master_ssl_dir}/certs"
  $pe_master_ssl_public_key_dir       = "${pe_master_ssl_dir}/public_keys"
  $pe_master_ssl_private_key_dir      = "${pe_master_ssl_dir}/private_keys"
  $pe_console_share_dir               = '/opt/puppet/share/puppet-dashboard'
  $pe_console_internal_cert_dir       = "${pe_console_share_dir}/certs"

  $pe_master_owner                    = 'pe-puppet'
  $pe_master_group                    = 'pe-puppet'
  $pe_console_owner                   = 'puppet-dashboard'
  $pe_console_group                   = 'puppet-dashboard'
  #############################################################################
  ## For the MoM servers
  #############################################################################
  # Domains for MoM servers and tenant PE servers
  # NOTE: May not need this - all tenants may be in the same domain as the MoM servers

  $pe_mom_console_hostname            = 'pe-console'
  $pe_mom_console_fqdn                = "${pe_mom_console_hostname}.${pe_mom_domain}"

  $pe_mom_puppetdb_hostname           = 'pe-puppetdb'
  $pe_mom_puppetdb_fqdn               = "${pe_mom_puppetdb_hostname}.${pe_mom_domain}"

  $pe_mom_master_hostname             = 'pe-master'
  $pe_mom_master_fqdn                 = "${pe_mom_master_hostname}.${pe_mom_domain}"

  $pe_mom_consolepg_hostname          = $pe_mom_puppetdb_hostname
  $pe_mom_consolepg_fqdn              = "${pe_mom_consolepg_hostname}.${pe_mom_domain}"

  $pe_mom_puppetdbpg_hostname         = $pe_mom_puppetdb_hostname
  $pe_mom_puppetdbpg_fqdn             = "${pe_mom_puppetdbpg_hostname}.${pe_mom_domain}"

  $pe_mom_console_pgdb_password       = 'strongpassword2025'
  $pe_mom_consoleauth_pgdb_password   = 'strongpassword1905'
  $pe_mom_puppetdb_pgdb_password      = 'strongpassword1748'

  ## PuppetDB Whitelist
  $pe_mom_puppetdb_whitelist = [
    $::clientcert,
    $pe_console_certname,
    $pe_mom_ca_fqdn,
  ]

  ## Console authorizations
  $pe_mom_console_authorizations = {
    'pe-internal-dashboard' => {
      'role'                => 'read-write'
    },
    "${::clientcert}"       => {
      'role'                => 'read-write'
    },
    "${pe_mom_ca_fqdn}"     => {
      'role'                => 'read-write'
    },
  }

  ## Mcollective
  $pe_mom_stomp_servers = [
    $pe_mom_ca_fqdn,
  ]

  $control_repo_address = 'https://github.com/gsarjeant/puppet-master-of-masters'
  #############################################################################

  # Tenant variables

  $pe_tenant_master_hostname           = 'pe-master'
  $pe_tenant_master_fqdn               = "${pe_tenant_master_hostname}.${pe_tenant_domain}"

  $pe_tenant_console_hostname          = 'pe-console'
  $pe_tenant_console_fqdn              = "${pe_tenant_console_hostname}.${pe_tenant_domain}"

  $pe_tenant_puppetdb_hostname         = 'pe-puppetdb'
  $pe_tenant_puppetdb_fqdn             = "${pe_tenant_puppetdb_hostname}.${pe_tenant_domain}"

  $pe_tenant_consolepg_hostname        = $pe_tenant_puppetdb_hostname
  $pe_tenant_consolepg_fqdn            = "${pe_tenant_consolepg_hostname}.${pe_tenant_domain}"

  $pe_tenant_puppetdbpg_hostname       = $pe_tenant_puppetdb_hostname
  $pe_tenant_puppetdbpg_fqdn           = "${pe_tenant_puppetdbpg_hostname}.${pe_tenant_domain}"

  $pe_tenant_console_pgdb_password       = 'strongpassword2025'
  $pe_tenant_consoleauth_pgdb_password   = 'strongpassword1905'
  $pe_tenant_puppetdb_pgdb_password      = 'strongpassword1748'

  ## PuppetDB Whitelist
  $pe_tenant_puppetdb_whitelist = [
    $pe_tenant_master_fqdn,
    $::clientcert,
    $pe_console_certname,
  ]

  ## Console authorizations
  $pe_tenant_console_authorizations = {
    'pe-internal-dashboard' => {
      'role'                => 'read-write'
    },
    "${::clientcert}"       => {
      'role'                => 'read-write'
    },
    "${pe_tenant_master_fqdn}" => {
      'role'                => 'read-write'
    },
  }

}
