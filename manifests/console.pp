# profile to be applied to Puppet Enterprise Console servers (aharden@te.com)
# puppetversion case can be removed after decom of PE 3.3.2
class te_puppet::console (
  $certificate_list,
  $console_auth_pwd,
  $console_db_pwd,
  $dashboard_workers = '2', # default number of dashboard workers
  $ldap_pwd,
  $db_host = 'localhost',
) {
  include ::te_puppet::common
  include ::rsync
  $rsync_dest_host = $::te_puppet::common::rsync_dest_host
  $rsync_dest_path = $::te_puppet::common::rsync_dest_path

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

  case $::pe_version {
    '3.3.2': {
      #$database_yml_file = 'database.yml.pe33.erb'

      file {'/etc/puppetlabs/console-auth/cas_client_config.yml':
        ensure => 'file',
        source => "puppet:///modules/${module_name}/console-auth/cas_client_config.yml",
      }

      file {'/etc/puppetlabs/rubycas-server/config.yml':
        ensure  => 'file',
        content => template("${module_name}/rubycas-server/config.yml.erb"),
        group   => 'pe-auth',
        mode    => '0600',
      }

      file { $dashboard_workers_path:
        ensure  => 'file',
        content => template("${module_name}/puppet-dashboard/pe-puppet-dashboard-workers.erb"),
        owner   => 'root',
        group   => 'root',
      }

      file {'/etc/puppetlabs/console-auth/certificate_authorization.yml':
        ensure  => file,
        content => template("${module_name}/console-auth/certificate_authorization.yml.erb"),
      }

      service {'pe-puppet-dashboard-workers':
        ensure => 'running',
        enable => true,
      }
    }
    default: {
      #$database_yml_file = 'database.yml.erb'

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
  }

  # removing this management pending review after PE 3.7 deployment
  #file {'/etc/puppetlabs/puppet-dashboard/database.yml':
  #  ensure  => file,
  #  content => template("${module_name}/puppet-dashboard/$database_yml_file"),
  #  owner   => 'puppet-dashboard',
  #}

  # rsync target for /opt/puppet/share/puppet-dashboard/certs file backups
  rsync::put { "${rsync_dest_host}:${rsync_dest_path}/${::puppetdeployment}\
    /${::hostname}/opt/puppet/share/puppet-dashboard/certs":
    user    => 'root',
    keyfile => '/root/.ssh/id_rsa.pub',
    source  => '/opt/puppet/share/puppet-dashboard/certs',
  }
}
