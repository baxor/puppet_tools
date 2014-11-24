#   x_packages -- meta function for helping track shared packages scross a puppet tree.
#   Usage:   
#
# 28   packages::x_package{ [ 'git', 'facter', 'expect', 'sysstat', 'curl' ]: }
# 29   packages::x_package{ 'base-lvm2': x_title => 'lvm2' }
# 30   host { $fqdn:
# 31     ip => $ipaddress_eth0,
# 32   }
# 33   if $osfamily == 'Debian' {
# 34     packages::x_package { 'linux-image-3.13.0-30-generic':
# 35       x_ensure => '3.13.0-30.55',
# 36     }
# 37   }
#
#
class packages {
  #class { 'repo::unauth': }  #class to enable unauthorized/unsigned package installs
  exec { 'easy_install_pip':
    command => '/usr/bin/easy_install pip && touch /var/lib/masterless/receipts/.easy_install_pip_p',
    creates => '/var/lib/masterless/receipts/.easy_install_pip_p',
  }->
  file { '/usr/bin/pip':
    ensure  => link,
    target  => '/usr/local/bin/pip',
  }

  @package {
    [ 'lvm2', 'git', 'facter', 'expect', 'sysstat', 'curl' ]:
      ensure => installed;
    [ 'ruby-dev', 'build-essential', 'tzdata', 'python-dev' ]:
      ensure    => installed;
    'flask':
      ensure    => installed,
      provider  => 'pip',
      require   => Exec['easy_install_pip'];
    'python-pip':
      ensure    => installed;
    'jgrep':
      ensure    => installed,
      provider  => 'gem';
  }

  realize(Package['build-essential'])

  #
  # Do not modify below this line
  #
  define x_package(
    $x_title              = undef,
    $x_name               = undef,
    $x_ensure             = undef,
    $x_adminfile          = undef,
    $x_allowcdrom         = undef,
    $x_category           = undef,
    $x_configfiles        = undef,
    $x_description        = undef,
    $x_flavor             = undef,
    $x_install_options    = undef,
    $x_instance           = undef,
    $x_platform           = undef,
    $x_provider           = undef,
    $x_responsefile       = undef,
    $x_root               = undef,
    $x_source             = undef,
    $x_status             = undef,
    $x_uninstall_options  = undef,
    $x_vendor             = undef,
    $x_alias              = undef,
    $x_audit              = undef,
    $x_before             = undef,
    $x_loglevel           = undef,
    $x_noop               = undef,
    $x_notify             = undef,
    $x_require            = undef,
    $x_schedule           = undef,
    $x_subscribe          = undef,
    $x_tag                = undef,
    ) {
    $y_title = $x_title ? { undef => $title, default => $x_title }
    if ! defined(Package[$y_title]) {
      @package { $y_title:
        name               => $x_name,
        ensure             => $x_ensure,
        adminfile          => $x_adminfile,
        #allow_virtual      => $x_allow_virtual,
        allowcdrom         => $x_allowcdrom,
        category           => $x_category,
        configfiles        => $x_configfiles,
        description        => $x_description,
        flavor             => $x_flavor,
        install_options    => $x_install_options,
        instance           => $x_instance,
        #package_settings   => $x_package_settings,
        platform           => $x_platform,
        provider           => $x_provider,
        responsefile       => $x_responsefile,
        root               => $x_root,
        source             => $x_source,
        status             => $x_status,
        uninstall_options  => $x_uninstall_options,
        vendor             => $x_vendor,
        alias              => $x_alias,
        audit              => $x_audit,
        before             => $x_before,
        loglevel           => $x_loglevel,
        noop               => $x_noop,
        notify             => $x_notify,
        require            => $x_require,
        schedule           => $x_schedule,
        subscribe          => $x_subscribe,
        tag                => $x_tag,
      }
      realize(Package[$y_title])
    } else {
      notice("Attempting to realize Package: ${y_title} - move existing package definition to common::packages if this fails.")
      realize(Package[$y_title])
    }
  }
}
