class profile::puppet::master {

  ## Global variables for PE configuration
  include profile::params

  ## File ownership defaults
  File {
    owner => $::profile::params::pe_master_owner,
    group => $::profile::params::pe_master_group,
  }

  ## Mcollective servers
  $stomp_servers = join($profile::params::pe_tenant_stomp_servers, ',')

  ## Manage various architecture settings, such as CA settings
  class { 'pe_server':
    is_master                    => true,
    ca_server                    => $profile::params::pe_mom_ca_fqdn,
    export_console_authorization => false,
    export_puppetdb_whitelist    => false,
  }

  # We'll need to manage the console's internal certs from here. Make sure the directories exist.
  file { $::profile::params::pe_console_share_dir:
    ensure => directory,
    mode  => '0755',
  }

  file { $::profile::params::pe_console_internal_cert_dir:
    ensure => directory,
    owner => $::profile::params::pe_master_owner,
    group => $::profile::params::pe_master_group,
  }

  ## Configure Mcollective 
  ## we want to share credentials and provide multiple brokers
  class { 'pe_server::mcollective':
    primary            => $profile::params::pe_mom_ca_fqdn,
    shared_credentials => true,
    activemq_brokers   => $profile::params::pe_activemq_brokers,
  }

  ## Create site.pp from a static file
  ## We don't have a good way to inject the role inclusion otherwise
  ## Set the stomp servers as a top-scope variable in site.pp
  file { "${::settings::confdir}/manifests/site.pp":
    ensure => 'present',
    source => 'puppet:///modules/profile/etc/puppetlabs/puppet/manifests/site.pp',
    notify => Service[ 'pe-httpd' ],
  }

  ## Configure r10k
  class { 'r10k':
    sources       => {
      'infra'   => {
        'remote'  => $profile::params::control_repo_address,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    },
    purgedirs         => [ "${::settings::confdir}/environments" ],
    manage_modulepath => false,
    mcollective       => false,
    notify            => Service['pe-httpd'],
  }

  ## Ensure an environments directory exists
  file { "${::settings::confdir}/environments":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  ## Configure Puppet's base module path - where can it find 'global' modules
  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules",
    notify  => Service['pe-httpd'],
  }

  ## Configure Puppet's environment path - where can it find environments
  ini_setting { 'environmentpath':
    ensure => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => "${::settings::confdir}/environments",
    notify  => Service['pe-httpd'],
  }

  ## Manage the pe-httpd service here, so we can notify it
  service { 'pe-httpd':
    ensure => 'running',
    enable => true,
  }

}
