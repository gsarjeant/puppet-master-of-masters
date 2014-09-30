## Refer to https://github.com/adrienthebo/r10k/blob/master/doc/puppetfile.mkd
## for information on what this file is and how to use it.

## Modules can be installed using the Puppet module tool.
## Consider http(s) proxies when installing modules.
## If no version is specified the latest version available at the time will be installed, and will be kept at that version.
##   mod 'puppetlabs/apache'
## If a version is specified then that version will be installed.
##   mod 'puppetlabs/apache', '0.10.0'
## If the version is set to :latest then the module will be always updated to the latest version available.
##   mod 'puppetlabs/apache', :latest

mod 'pe_server',
  :git => 'https://github.com/joshbeard/pe_server.git',
  :ref => '3.3.x'

mod 'puppet_certificate',
  :git => 'https://github.com/reidmv/puppet-module-puppet_certificate.git',
  :ref => '0.0.2'

###############################################################################
# General dependencies

mod 'stdlib',
  :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git'

mod 'inifile',
  :git => 'https://github.com/puppetlabs/puppetlabs-inifile.git'

mod 'concat',
  :git => 'https://github.com/puppetlabs/puppetlabs-concat.git'

mod 'hiera',
  :git => 'https://github.com/hunner/puppet-hiera.git'

mod 'ruby',
  :git => 'https://github.com/puppetlabs/puppetlabs-ruby.git'

mod 'gcc',
  :git => 'https://github.com/puppetlabs/puppetlabs-gcc.git'

mod 'pe_gem',
  :git => 'https://github.com/puppetlabs/puppetlabs-pe_gem.git'

mod 'vcsrepo',
  :git => 'https://github.com/puppetlabs/puppetlabs-vcsrepo.git'

mod 'git',
  :git => 'https://github.com/puppetlabs/puppetlabs-git.git'

mod 'make',
  :git => 'https://github.com/Element84/puppet-make.git'

mod 'r10k',
  :git => 'https://github.com/acidprime/r10k.git',
  :ref => 'v2.2.1'

mod 'staging',
  :git => 'https://github.com/nanliu/puppet-staging.git'

###############################################################################
