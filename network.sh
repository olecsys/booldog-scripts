#!/usr/bin/env bash

function check_variable_existence() {
  [ -z ${1+abc} ] && return 1 || return 0
}

function network_get_backend() {
  check_variable_existence $1 \
    && local __backend=${1} \
    || local __backend=

  if [ -z "$__backend" ] || [ "$__backend" = "curl" ]; then
    command -v curl > /dev/null 2>&1 && {
      echo curl;
      return 0;
    }
  fi

  if [ -z "$__backend" ] || [ "$__backend" = "wget" ]; then
    command -v wget > /dev/null 2>&1 && {
      echo wget;
      return 0;
    }
  fi
  return 1
}

function network_download_file() {
  [ "$(type -t check_variable_existence)" = function ] || {
    >&2 echo -e 'Shell function '${redbold}'`check_variable_existence`'${red}' does not exist.';
    }

  local red='\e[0;31m'
  local redbold='\e[1;31m'

  check_variable_existence $1 \
    || { 
      >&2 echo -e 'Please pass '${redbold}'`url`'${red}' as first parameter of the '${redbold}'`network_download_file`'${red}' function.';
      return 1;
      }

  local __url=${1}
  __url=$(sed 's/\s/%20/g' <<<"${__url}")

  check_variable_existence $2 \
    && local __output_file=${2} \
    || local __output_file=$(basename "${__url}")

  check_variable_existence $3 \
    && local __check_ssl_cert=${3} \
    || local __check_ssl_cert=1

  check_variable_existence $4 \
    && local __backend=${4} \
    || local __backend=
  
  local __output_file=$(realpath "${__output_file}")

  local __download_command=
  __download_command=$(network_get_backend ${__backend})

  [ -d "${__output_file}" ] \
    && __output_file=${__output_file}'/'$(basename "${__url}")

  case $__download_command in
    curl)
      [ ${__check_ssl_cert} -eq 1 ] \
        && __download_command=curl\ -L\ ${__url}\ -o\ "${__output_file}" \
        || __download_command=curl\ -L\ -k\ ${__url}\ -o\ "${__output_file}"
      ;;
    wget)
      [ ${__check_ssl_cert} -eq 1 ] \
        && __download_command=wget\ ${__url}\ -O\ "${__output_file}" \
        || __download_command=wget\ --no-check-certificate\ ${__url}\ -O\ "${__output_file}"
      ;; 
    *)
      >&2 echo -e "Cannot find ${redbold}curl${red} or ${redbold}wget${red}. Please install ${redbold}curl${red} or ${redbold}wget${red} and try again.";
      return 1;
      ;;
  esac

  __download_command=$(sed 's/[\*\.&]/\\&/g' <<<"${__download_command}")

  eval "${__download_command}" 2>&1 >/dev/tty || return 1

  return 0
}

function network_get_data() {
  [ "$(type -t check_variable_existence)" = function ] || {
    >&2 echo -e 'Shell function '${redbold}'`check_variable_existence`'${red}' does not exist.';
    }

  local red='\e[0;31m'
  local redbold='\e[1;31m'

  check_variable_existence $1 \
    || { 
      >&2 echo -e 'Please pass '${redbold}'`url`'${red}' as first parameter of the '${redbold}'`network_get_data`'${red}' function.';
      return 1;
      }

  local __url=${1}
  __url=$(sed 's/\s/%20/g' <<<"${__url}")

  check_variable_existence $2 \
    && local __check_ssl_cert=${2} \
    || local __check_ssl_cert=1

  check_variable_existence $3 \
    && local __backend=${3} \
    || local __backend=

  local __download_command=
  __download_command=$(network_get_backend ${__backend})

  local __download_args=
  case $__download_command in
    curl)
      [ ${__check_ssl_cert} -eq 1 ] && {
        __download_command='curl -s -L '${__url};
      } || {
        __download_command='curl -s -L -k '${__url};
      }
      ;;
    wget)
      [ ${__check_ssl_cert} -eq 1 ] && { 
        __download_command='wget -q -O - '${__url};
      } || {
        __download_command='wget -q -O - --no-check-certificate '${__url};
      }
      ;; 
    *)
      >&2 echo -e "Cannot find ${redbold}curl${red} or ${redbold}wget${red}. Please install ${redbold}curl${red} or ${redbold}wget${red} and try again.";
      return 1;
      ;;
  esac  
  
  __download_command=$(sed 's/[\*\.&]/\\&/g' <<<"${__download_command}")  

  eval "${__download_command}" || return 1

  return 0
}
