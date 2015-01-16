#requires a run_once{} resource (or any exec block, if you're grok the pattern)
define common::run_again($receiptdir=$common::receipt_dir) {
  file { "${receiptdir}/.${title}_p":
    ensure => absent,
    notify => Exec[$title],
  }
}
