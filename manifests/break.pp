define common::break($receiptdir=$common::receipt_dir, $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin') {
  exec { "break_for_${title}":
    command => "bash -c 'while [ ! -e ${receiptdir}/${title} ]; do sleep 2; done && rm -f ${receiptdir}/continue'"
    path => $path,
    creates => "${receiptdir}/${title}",
    require => File[$receiptdir],
  }
}
