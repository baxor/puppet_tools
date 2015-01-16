define common::break($timeout=120, $sleep=2, $receiptdir=$common::receipt_dir, $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin') {
  #universal compatible:
  exec { "break_for_${title}":
    command => "bash -c 'while [ ! -e ${receiptdir}/${title} ]; do sleep ${sleep}; done && rm -f ${receiptdir}/${title}'"
    path => $path,
    timeout => $timeout, 
    creates => "${receiptdir}/${title}",
    require => File[$receiptdir],
  }
  #Alternate (puppet 3+):
#define common::break($tries=30, $sleep=2, $receiptdir=$common::receipt_dir, $path='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin') {
#  exec { "break_for_${title}":
#    command => "ls ${receiptdir}/${title} && rm -f ${receiptdir}/${title}",
#    path => $path, 
#    tries => $tries, 
#    try_sleep => $sleep, 
#    require => File[$receiptdir],
#  }
}
