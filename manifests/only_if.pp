# **** FUN TIMES! ****
#  Abusing onlyif and notify chaining to provide conditional execution
#  that -doesnt- result in a failed resource resolution
#=============
# Example:
#  common::only_if{ 'docker_stop':
#    test => 'pidof docker',
#    cmd => 'service docker stop',
#    condition => 'test ! mount |grep -i /var/lib/docker'
#  }

define common::only_if($test, $cmd, $condition='/bin/true', $exit_code='0', $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin') {
  exec { "${title}_condition":
    command => '/bin/true',
    onlyif => $condition,
    path => $path,
    notify => Exec["${title}_test"],
  }
  exec { "${title}_test":
    command => '/bin/true',
    path => $path,
    onlyif => $test,
    returns => $exit_code,
    refreshonly => true,
    notify => Exec["${title}_run"],
    require => Exec["${title}_condition"],
  }
  exec { "${title}_run":
    command => $cmd,
    path => $path,
    refreshonly => true,
    require => Exec["${title}_test"],
  }
}
