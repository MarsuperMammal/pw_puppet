# profile to be applied to Puppet Enterprise Console servers (aharden@te.com)
# puppetversion case can be removed after decom of PE 3.3.2
class te_puppet::console (
  $console_db_pwd,
  $dashboard_workers = '2', # default number of dashboard workers
  $db_host = 'localhost',
) inherits te_puppet {
  File {
    owner  => 'pe-auth',
    group  => 'puppet-dashboard',
    mode   => '0640',
    notify => Service['pe-puppet-dashboard-workers','pe-httpd'],
  }

  case $::osfamily {
    'debian': {
      $dashboard_workers_path = '/etc/default/pe-puppet-dashboard-workers'
    }
    'redhat': {
      $dashboard_workers_path = '/etc/sysconfig/pe-puppet-dashboard-workers'
    }
    default:  {
      notify("No dashboard workers configuration defined for ${::osfamily}.")
    }
  }

  file {'/etc/puppetlabs/puppet-dashboard/database.yml':
    ensure  => file,
    content => template("${module_name}/puppet-dashboard/database.yml.erb"),
    owner   => 'puppet-dashboard',
  }

  # Config file to control session duration
  # Reference: https://docs.puppetlabs.com/pe/latest/console_config.html
  file {'/etc/puppetlabs/console-services/conf.d/session-duration.conf':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/console-services/session-duration.conf",
    group  => 'pe-console-services',
    owner  => 'pe-console-services',
    mode   => '0640',
    notify => Service['pe-console-services'],
  }
}
