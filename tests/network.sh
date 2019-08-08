#!/bin/bash

function test_network_download_file() {
  local __url=${1}
  local __output_file=${2}
  local __check_ssl_cert=${3}
  local __backend=${4}
  local __sha256output=${5}

  local __funcerror=
  __funcerror=$(network_download_file ${__url} "${__output}" 1 ${__backend} 2>&1 >/dev/tty) || {
    >&2 echo -e "${__funcerror}";
    return 1;
  }

  local __downloaded_jq_linux64_sha256=
  __downloaded_jq_linux64_sha256=$(sha256sum "${__output_file}") || {
    >&2 echo -e "${__downloaded_jq_linux64_sha256}";
    return 1;
  }
  __downloaded_jq_linux64_sha256=( ${__downloaded_jq_linux64_sha256} )

  __downloaded_jq_linux64_sha256=${__downloaded_jq_linux64_sha256[0]}

  [ "${__sha256output}" = "${__downloaded_jq_linux64_sha256}" ] || {
    >&2 echo -e 'sha256 hash sum('${__downloaded_jq_linux64_sha256}') of the downloaded file('${__url}') via '${__backend}' does not equal to '${__sha256output};
    return 1;
  }

  return 0;
}

function test_network_get_data() {
  local __url=${1}
  local __check_ssl_cert=${2}
  local __backend=${3}

  local __funcerror=
  __funcerror=$(network_get_data ${__url} 1 ${__backend}) || {
    >&2 echo -e "${__funcerror}";
    return 1;
  }
  echo -e "${__funcerror}"
  return 0
}

function main() {
  local old_dir="`pwd`/`basename "$0"`"
  old_dir=`dirname "$old_dir"`
  cd "`dirname "$0"`"
  local script_dir="`pwd`/`basename "$0"`"
  script_dir=`dirname "$script_dir"`
  cd "$old_dir"

  . "$script_dir/../network.sh"

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local __funcerror=     # set `__funcerror` variable with custom error message
  local __funcresult=1   # set `__funcresult` variable with script result

  while true
  do
    [ "$(type -t network_download_file)" = function ] || {
      __funcerror=$(echo -e 'Shell function '${redbold}'`network_download_file`'${red}' does not exist.');
      break;
    }

    [ "$(type -t network_get_data)" = function ] || {
      __funcerror=$(echo -e 'Shell function '${redbold}'`network_get_data`'${red}' does not exist.');
      break;
    }

    local __jq_linux64_sha256=af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44

    local __output=$(dirname $(mktemp -u))'/booldog-network-test-jq-linux64'
    local __url=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64

    __funcerror=$(test_network_download_file ${__url} \
      "${__output}" \
      1 \
      "curl" \
      ${__jq_linux64_sha256} 2>&1 >/dev/tty) || {
      break
    }

    __funcerror=$(test_network_download_file ${__url} \
      "${__output}" \
      1 \
      "wget" \
      ${__jq_linux64_sha256} 2>&1 >/dev/tty) || {
      break
    }

    __url=https://api.github.com/users/olecsys/repos

    local __output0=
    __output0=$(test_network_get_data ${__url} \
      1 \
      "curl") || {
      __funcerror="${__output0}"
      break
    }

    local __output1=
    __output1=$(test_network_get_data ${__url} \
      1 \
      "wget") || {
      __funcerror="${__output1}"
      break
    }

    [ "${__output0}" = "${__output1}" ] || {
      __funcerror=$(echo -e ${redbold}'`curl`'${red}' response does not equal to '${redbold}'`wget`'${red}' response.');
      break;
    }

    __funcresult=0
    break
  done  
  
  cd "$old_dir"

  while true
  do
    [ ! -z "$__funcerror" ] \
        && { echo -e "
${red}${__funcerror}${nocolor}
" 1>&2 ; __funcresult=1 ; break; }
    
    [ $__funcresult -eq 0 ] \
        && { echo -e '
'${greenbold}'network.sh test'${green}' is succeeded
'${nocolor} ; break; }
        
    echo -e '
'${redbold}'network.sh test'${red}' is failed
'${nocolor} 1>&2
    
    break
  done

  exit $__funcresult
}
main $@