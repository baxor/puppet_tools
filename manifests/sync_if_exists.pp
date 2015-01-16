#playing with the only_if pattern to provide more complex types
# We invoke rsync such that the $dest} should be the parent folder
define common::sync_if_exists ($src, $dest, $cleanup=false, $condition='/bin/true', $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin') {
  #default: don't be destructive, run `true`
  $cleanup_cmd = $cleanup ? {
    false => '/bin/true',
    true => "rm -rf ${src}",
  }

  # Allow the user to define a conditional command, which we default to `true`
  # such the default behavior triggers notify chaining down the exec tree
  exec { "sync_${title}_condition":
    command => '/bin/true',
    onlyif => $condition,
    path => $path,
    notify => Exec["sync_${title}_test_src"],
  }
  exec { "sync_${title}_test_src":
    command => '/bin/true',
    onlyif => "/usr/bin/test -e ${src}",
    path => $path,
    refreshonly => true,
    notify => Exec["sync_${title}"],
    require => Exec["sync_${title}_condition"],
  }
  #destination folder must exist
  exec { "sync_${title}":
    command => "rsync -avXS ${src} ${dest} && ${cleanup_cmd}",
    onlyif => "/usr/bin/test -e ${dest}",
    path => $path,
    timeout => 1800,
    refreshonly => true,
    require => Exec["sync_${title}"],
  }
}
