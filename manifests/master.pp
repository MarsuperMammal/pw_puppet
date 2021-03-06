# a class for servers with the Puppet Enterprise master role installed
# don't apply directly to roles:
#   use te_puppet::master::ca or te_puppet::master::compile profiles
class pw_puppet::master {
  include ::limits
  include ::r10k
  include ::r10k::mcollective
  include ::r10k::webhook
  include ::r10k::webhook::config
  Class['::r10k::webhook::config'] -> Class['::r10k::webhook']

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  Ini_setting {
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
  }

  case $::osfamily {
    'Debian': {
      package { 'daemon': # required by r10k webhook
        ensure => 'latest',
      }
    }
    default: {}
  }

  ini_setting { 'puppet configration dir path':
    setting => 'confdir',
    value   => '/etc/puppetlabs/puppet',
  }

  ini_setting { 'puppet base module path':
    setting => 'basemodulepath',
    value   => '$confdir/modules:/opt/puppet/share/puppet/modules',
  }

  ini_setting { 'puppet environment path':
    setting => 'environmentpath',
    value   => '$confdir/environments',
  }

  file { $settings::hiera_config:
    ensure => file,
    source => "puppet:///modules/${module_name}/hiera.yaml",
    notify => Service['pe-puppetserver'],
  }

}
