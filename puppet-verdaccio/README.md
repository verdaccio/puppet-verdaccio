# puppet-verdaccio module

## Overview

Install verdaccio npm-cache-server (https://github.com/verdaccio/verdaccio) for Debian, Ubuntu, Fedora, and RedHat.


## Usage

There are two variants to install verdaccio using this Puppet module: Apply-mode (with puppet-apply and no puppetmaster setup needed) or Master-Agent-mode (with puppet-agent accessing your configuration through the puppetmaster). In both variants you have to explicitely call "class nodejs {}" in your puppet script because the puppet-verdaccio module only defines this as a requirement, so you have all the flexibility you want when installing nodejs. Scroll down for details about Master-Agent-mode variant.

### General usage

#### class verdaccio

Installs verdaccio + required npms in one defined directory and integrates the verdaccio as a service (/etc/init.d/verdaccio). It also creates a user to run the verdaccio server (default: verdaccio). If you wish, you can change the username, see examples below.

Examples:

minimal:

```bash
  class { '::verdaccio':
    conf_admin_pw_hash => 'your-pw-hash',
  }
```

You can generate the admin password hash according to https://github.com/verdaccio/verdaccio via command-line:

```bash
  $ node
  > crypto.createHash('sha1').update('your-admin-password').digest('hex')
```

You can also override several configuration parameters.

```bash
  class { '::verdaccio':
    install_root       	    => '/usr/local',
    install_dir        	    => 'verdaccioxy',
    conf_admin_pw_hash 	    => 'your-pw-hash',
    conf_port          	    => '8080',
    deamon_user        	    => 'verdaccioxy',
    conf_listen_to_address  => '127.0.0.1',
    http_proxy              => 'http://proxy.com:3128',
    https_proxy             => 'http://proxy.com:3128',
    conf_template           => 'mymodule/config.yaml.erb',
    service_template        => 'mymodule/service.erb',    
    conf_max_body_size	    => '10mb',
    conf_max_age_in_sec	    => '604800',
    install_as_service	    => false,
  }
```

The default values for all so far configurable parameters are:

```bash  
  class { '::verdaccio':
    install_root       	      => '/opt',
    install_dir        	      => 'verdaccio',
    deamon_user        	      => 'verdaccio',
    conf_listen_to_address    => '0.0.0.0',
    conf_port          	      => '4783',
    conf_admin_pw_hash
    conf_user_pw_combinations => undef,
    http_proxy                => '',
    https_proxy               => '',
    conf_template             => 'verdaccio/config.yaml.erb',
    service_template          => 'verdaccio/service.erb',
    conf_max_body_size	      => '1mb',
    conf_max_age_in_sec	      => '86400',
    install_as_service	      => true,
  }
```





### Master-Agent-mode installation

In your puppet script for your agent add:
```bash  
  class { 'nodejs':
    # this automatically installs nodejs and npm
    make_default => true,
 }
  class { '::verdaccio':
    conf_admin_pw_hash => 'your-pw-hash',
  }
```

## Supported Platforms

The module has been tested on the following operating systems. Testing and patches for other platforms are welcome.

* RedHat EL7.

