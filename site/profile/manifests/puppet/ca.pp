class profile::puppet::ca {

  include profile::params

  case $::clientcert {
    $profile::params::pe_mom_ca_fqdn: {
      $active_ca      = true
      $generate_certs = undef
    }
    default: {
      $active_ca      = false
      $generate_certs = undef
    }
  }

  ## Add these to the autosign list
  ## Keep in mind, certs with additional names cannot be autosigned
  $autosign = [
    $profile::params::pe_console_certname,
    $profile::params::pe_mom_puppetdb_fqdn,
    $profile::params::pe_mom_console_fqdn,
    $profile::paras::pe_tenant_master_fqdn,
    $profile::paras::pe_tenant_puppetdb_fqdn,
    $profile::paras::pe_tenant_console_fqdn
  ]

  class { 'pe_server::ca':
    active_ca                 => $active_ca,
    autosign                  => $autosign,
    generate_certs            => $generate_certs,
    notify                    => Service['pe-httpd'],
  }

}
