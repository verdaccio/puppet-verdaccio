define verdaccio::package (
  $order         = '001',
  $install_path  = '/opt/verdaccio',
  $allow_access  = 'authenticated',
  $allow_publish = 'admin',
  $proxy         = 'DEFAULT',
  $storage       = 'DEFAULT',
) {
  $package = $title
  concat::fragment { "config.yaml > packages > ${package}":
    target  => "${install_path}/config.yaml",
    content => template('verdaccio/package.erb'),
    order   => $order,
  }
}
