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
  $conf_port                 = '4873',
  $conf_admin_pw_hash        = undef,
  $conf_user_pw_combinations = undef,
  $http_proxy                = '',
  $https_proxy               = '',
  $conf_template             = 'verdaccio/config.yaml.erb',
  $service_template          = 'verdaccio/service.erb',
  $service_ensure            = 'running',
  $conf_max_body_size        = '1mb',
  $conf_max_age_in_sec       = '86400',
  $install_as_service        = true,
  $public_npmjs_proxy        = true,
  $url_prefix                = undef,
  $time_out                  = undef,
  $htpasswd_auth             = false,) {
  require nodejs
  $install_path = "${install_root}/${install_dir}"

  if !($conf_admin_pw_hash or $htpasswd_auth) {
    fail('Supply $conf_admin_pwd_hash or set $htpasswd_auth => true')
  }

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

  $service_notify = $install_as_service ? {
    default => undef,
    true => Service['verdaccio']
  }
  $npm_ensure = $version ? {
    undef => 'latest',
    default => $version
  }
  nodejs::npm { $package_name:
    ensure   => $npm_ensure,
    target   => $install_path,
    user     => $daemon_user,
    home_dir => "/home/${daemon_user}/.npm",
    require  => [File[$install_path],User[$daemon_user]],
    notify   => $service_notify,
  }

###
# config.yaml requires $admin_pw_hash, $port, $listen_to_address
###
  concat { "${install_path}/config.yaml":
    owner          => $daemon_user,
    group          => $daemon_user,
    mode           => '0644',
    require        => File[$install_path],
    notify         => $service_notify,
    ensure_newline => true,
  }
  concat::fragment { 'config.yaml > except packages':
    target  => "${install_path}/config.yaml",
    content => template($conf_template),
    order   => '000000',
  }
  if $public_npmjs_proxy {
    verdaccio::package { '*':
      allow_access => 'all',
      proxy        => 'npmjs',
      install_path => $install_path,
      order        => 'ZZZZZZ',
    }
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
      ensure    => $service_ensure,
      enable    => true,
      hasstatus => true,
      restart   => true,
      require   => [
        File[
          $init_file,
          "${install_path}/daemon.log"
        ],
        Concat["${install_path}/config.yaml"],
      ],
    }
  }
}
