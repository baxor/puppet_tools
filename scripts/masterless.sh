#!/bin/bash
#Bugs:
LOCKFILE=/var/run/puppet_masterless.lock
MDIR=/var/lib/masterless
SCRIPTDIR=${MDIR}/script
TERM_TIMEOUT=30m
KILL_TIMEOUT=5m
GIT_REPO="GIT_REPO_URL"
GIT_CMD="env GIT_SSL_NO_VERIFY=true git"  #  Use self-signed certs
IFS='.'; DOMAIN=($(hostname -f)); unset IFS;
HOSTNAME=$(hostname)
ENV=${DOMAIN[1]}   #  Assume ENV.mycorp.com
DOMAINNAME="${DOMAIN[1]}.${DOMAIN[2]}"  
[[ ${#DOMAIN[@]} -eq 3 ]] && DOMAINNAME="${DOMAINNAME}.${DOMAIN[3]}"  
DOCKER_BUILD_FACT_FILE="${MDIR}/puppet/facts/docker-build-facts"  # read from fact-file dropped by dockerfile
FACTS_FILE="${MDIR}/puppet/facts/${HOSTNAME}.${DOMAINNAME}"  #read from host-specific fact file
[[ -e ${DOCKER_BUILD_FACT_FILE} ]] && { echo "[Docker]  Pulling in hardcoded facts from ${DOCKER_BUILD_FACT_FILE}"; . ${DOCKER_BUILD_FACT_FILE}; }
[[ -e ${FACTS_FILE} ]] && { echo "Pulling in hardcoded facts from ${FACTS_FILE}"; . ${FACTS_FILE}; }
[[ -d ${MDIR}/receipts ]] || mkdir -p ${MDIR}/receipts
[[ -e /etc/debian_version ]] && RUBY_PATH="/usr/lib/ruby/vendor_ruby" || RUBY_PATH="/usr/lib/ruby/site_ruby/1.8"
declare -A FILES=( ["ec2.rb"]="${RUBY_PATH}/facter" ["ec2tags.rb"]="${RUBY_PATH}/facter" ["foreman.rb"]="${RUBY_PATH}/puppet/reports" ["foreman_tags.rb"]="${RUBY_PATH}/facter" ["ipaddress.rb"]="${RUBY_PATH}/facter" )
export EC2_HOME="/opt/aws"
export JAVA_HOME="/usr"

ACTION=$1

switch_repo() {    # Switch branches based off of environment, overrid by fact tag. 
  if [ "${ENV}" == "qa" ]; then
    SYSTEMBRANCH=qa;
  elif   [[ "$HOSTNAME" =~ ^qa.* ]]; then
    SYSTEMBRANCH=qa;
  elif [[ "$HOSTNAME" =~ ^cm.* ]]; then  
    SYSTEMBRANCH=qa;
  elif [[ "$HOSTNAME" =~ ^sb.* ]]; then  
    SYSTEMBRANCH=qa;
  elif [[ "$HOSTNAME" =~ ^sb.* ]]; then  
    SYSTEMBRANCH=qa;
  elif [ "${ENV}" == "dev" ]; then
    SYSTEMBRANCH=dev;
  elif [[ "${HOSTNAME}" =~ ^dev.* ]]; then 
    SYSTEMBRANCH=dev;
  elif [ "${ENV}" == "prod" ]; then
    SYSTEMBRANCH=prod;
  else 
    SYSTEMBRANCH=prod;
  fi;
  LOGDEST='syslog'
  MASTERLESS_BRANCH=$(facter -p tag_masterless_branch)
  DOCKER=$(facter -p docker_container)
  [[ "${MASTERLESS_BRANCH}" == "" ]] || SYSTEMBRANCH=$MASTERLESS_BRANCH
  if [[ "${DOCKER}" == "true" ]] || [[ "${BOOTSTRAP}" == "true" ]]; then
    LOGDEST='/dev/stdout' 
  fi
  ${GIT_CMD} checkout ${SYSTEMBRANCH}
}

get_ionice() {
  #This is a stupid workaround
  #because when ionice fails under older redhat distros
  #it returns error code 0
  IONICE_COMMAND="ionice -c 3 -t"
  TEST=$($IONICE_COMMAND echo test 2> /dev/null)
  if [ "${TEST}" == "test" ]; then
    echo $IONICE_COMMAND
  else
    echo ""
  fi
}

get_timeout() {
  #Make sure the timeout command is working before trying it out
  TIMEOUT_COMMAND="timeout --kill-after=${KILL_TIMEOUT} ${TERM_TIMEOUT}"
  TEST=$($TIMEOUT_COMMAND echo test 2> /dev/null)
  if [ "${TEST}" == "test" ]; then
    echo $TIMEOUT_COMMAND
  else
    echo ""
  fi
}

check_req() {
  [ $(which puppet) ] || { echo "puppet not installed!"; exit 1; }
  [ $(which git) ] || { echo "git not installed!"; exit 1; }
  for i in "${!FILES[@]}" ; do 
    local destdir="${FILES[$i]}"
    local file="${MDIR}/script/ruby/${i}"
    [ "$(md5sum ${file}|awk '{print $1}')" == "$(md5sum ${destdir}/${i}|awk '{print $1}')" ] || { echo "copying ${file} to ${destdir}"; cp ${file} ${destdir} 2>/dev/null; }
  done
  grep stringify_facts /etc/puppet/puppet.conf || { 
    sed -i '/\[main\]/a \
stringify_facts = false' /etc/puppet/puppet.conf
  }
}

#TODO: parse status codes
#* --detailed-exitcodes:
#  Provide transaction information via exit codes. If this is enabled, an exit
#  code of '2' means there were changes, an exit code of '4' means there were
#  failures during the transaction, and an exit code of '6' means there were both
#  changes and failures.

run_puppet() {
  #If a repo is currently being cloned, it doesn't wait for it
  (
    flock -xn 200
    LOCKSTATUS=$?
    if [ $LOCKSTATUS != 0 ]; then
      echo "Error, there is something else that has locked the lockfile: ${LOCKFILE}"
      exit 1
    fi
    cd ${MDIR} || exit 10
    [ -d 'puppet' ] || ${GIT_CMD} clone ${GIT_REPO}
    cd puppet
    IONICE=$(get_ionice)
    TIMEOUT_COMMAND=$(get_timeout)
    ${GIT_CMD} pull
    switch_repo
    #Do not quit if pull goes wrong
    ${GIT_CMD} pull
    #Puppet is the least of your priorities:
    echo "Running puppet"
    $TIMEOUT_COMMAND $IONICE nice -n 19 puppet apply --write-catalog-summary --modulepath=${MDIR}/puppet/modules/ --logdest ${LOGDEST} --verbose ${MDIR}/puppet/manifests/site.pp
    echo "Done"
  ) 200> ${LOCKFILE}
}

case "${ACTION}" in
  "start")
    check_req
    run_puppet
    touch /var/lock/subsys/puppet
    ;;
  "stop")
    unlink /var/lock/subsys/puppet
    ;;
  "status")
    exit 0
    ;;
  "cron")
    check_req
    let _sleep=$[ ( $RANDOM % 90 )  + 5 ]
    echo "Sleeping for ${_sleep}s..."
    sleep ${_sleep}s
    run_puppet
    ;;
  *)
    check_req
    run_puppet
    ;;
esac
