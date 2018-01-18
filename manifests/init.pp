# Class: puppet-verdaccio
#
# This module manages verdaccio npm-cache-server installations.
#
# Parameters:
#
# conf_admin_pw_hash
# generate the password hash for your plain text password (e.g. newpass) with:
# $ node
# > crypto.createHash('sha1').update('newpass').digest('hex')
#
# conf_listen_to_address
# the ip4 address your proxy is supposed to listen to,
# default 0.0.0.0 (=all addresses)
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class verdaccio (
  $install_root              = '/opt',
  $install_dir               = 'verdaccio',
  $version                   = undef,    # latest
  $daemon_user               = 'verdaccio',
  $package_name              = 'verdaccio',
  $conf_listen_to_address    = '0.0.0.0',
  $conf_port                 = '4783',
  $conf_admin_pw_hash,
  $conf_user_pw_combinations = undef,
  $http_proxy                = '',
  $https_proxy               = '',
  $conf_template             = 'verdaccio/config.yaml.erb',
  $service_template          = 'verdaccio/service.erb',
  $conf_max_body_size        = '1mb',
  $conf_max_age_in_sec       = '86400',
  $install_as_service        = true,) {
  require nodejs
  $install_path = "${install_root}/${install_dir}"

  group { $daemon_user:
    ensure => present,
  }

  user { $daemon_user:
    ensure     => present,
    gid        => $daemon_user,
    managehome => true,
    require    => Group[$daemon_user]
  }

  file { $install_root:
    ensure => directory,
  }

  file { $install_path:
    ensure  => directory,
    owner   => $daemon_user,
    group   => $daemon_user,
    require => [User[$daemon_user], Group[$daemon_user]]
  }

### ensures, that always the latest versions of npm modules are installed ###
  $modules_path="${install_path}/node_modules"
  file { $modules_path:
    ensure => absent,
  }

  $service_notify = $install_as_service ? {
    default => undef,
    true => Service['verdaccio']
  }
  nodejs::npm { "${package_name}":
    ensure   => latest,
    target   => $install_path,
    home_dir => $install_path,
    require  => [File[$install_path,$modules_path],User[$daemon_user]],
    notify   => $service_notify,
    user     => $daemon_user,
  }

###
# config.yaml requires $admin_pw_hash, $port, $listen_to_address
###
  file { "${install_path}/config.yaml":
    ensure  => present,
    owner   => $daemon_user,
    group   => $daemon_user,
    content => template($conf_template),
    require => File[$install_path],
    notify  => $service_notify,
  }

  file { "${install_path}/daemon.log":
    ensure  => present,
    owner   => $daemon_user,
    group   => $daemon_user,
    require => File[$install_path],
  }

  if $install_as_service {
    $init_file = '/etc/init.d/verdaccio'

    file { $init_file:
      content => template($service_template),
      mode    => '0755',
      notify  => $service_notify,
    }

    service { 'verdaccio':
      ensure    => running,
      enable    => true,
      hasstatus => true,
      restart   => true,
      require   => File[
        $init_file,
        "${install_path}/config.yaml",
        "${install_path}/daemon.log"
      ]
    }
  }
}
