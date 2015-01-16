define common::run_once($cmd, $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin', $receiptdir=$common::receipt_dir) {
  exec { $title:
    command => "${cmd} && touch ${receiptdir}/.${title}_p",
    path => $path,
    creates => "${receiptdir}/.${title}_p",
    require => File[$receiptdir],
  }
}
