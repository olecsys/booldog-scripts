#!/usr/bin/env bash

function check_executable_exists() {
  command -v "$1" > /dev/null 2>&1
}

function get_script_name() {
  [ ! -z "${BASH_SOURCE[0]}" ] && {
    echo $(basename "${BASH_SOURCE[0]}")
    return 0
  }
  echo $(basename "$0")
  return 0
}

function get_script_dir() {
  [ -z "${BASH_SOURCE[0]}" ] && {
    >&2 echo 'BASH_SOURCE[0] is empty'
    return 1
  }
  local __old_dir=$(pwd)
  local __source="${BASH_SOURCE[0]}" __dir=
  while [ -h "${__source}" ]
  do
    __dir=$(dirname "${__source}")
    __dir="$(cd -P "${__dir}" >/dev/null 2>&1 && pwd)"
    __source="$(readlink "$__source")"
    [[ ${__source} != /* ]] && {
      __source="$(readlink "$__source")"
    }
  done
  __dir=$(dirname "${__source}")
  __dir="$(cd -P "${__dir}" >/dev/null 2>&1 && pwd)"
  cd "${__old_dir}"
  echo ${__dir}
  return 0
}

function json_get_jq_path() {
  local __jq_path="${HOME}/.booldog-scripts/jq"
  [ -f "${__jq_path}" ] && { echo "${__jq_path}"; return 0; }
  return 1
}

function json_install_jq() {
  local __script_name= __script_dir=
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local __jq_path="${HOME}/.booldog-scripts/jq"

  local __jq_dir_path=$(dirname "${__jq_path}")

  mkdir -p "${__jq_dir_path}" || return 1

  local __arch=$(uname -m) __url=
  case $__arch in
    x86_64)
      local __sha256sum=af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44
      __url=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
      ;;
    i386|i686)
      local __sha256sum=319af6123aaccb174f768a1a89fb586d471e891ba217fe518f81ef05af51edd9
      __url=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32
      ;;
    *)      
      >&2 echo -e ${red}'unsupported architecture: '${redbold}${__arch}${red}
      return 1
      ;;
  esac

  [ ! -f "${__jq_path}" ] && {
    . "${__script_dir}/network.sh"

    [ "$(type -t network_download_file)" = function ] || {
      >&2 echo -e 'Shell function '${redbold}'`network_download_file`'${red}' does not exist.';
    }

    local __funcerror=
    __funcerror=$(network_download_file ${__url} "${__jq_path}" 2>&1 >/dev/tty) || {
      >&2 echo -e "${__funcerror}";
      return 1;
    }
  }

  local __installed_jq_sha256=
  __installed_jq_sha256=$(sha256sum "${__jq_path}") || {
    >&2 echo -e "${__installed_jq_sha256}";
    return 1;
  }
  __installed_jq_sha256=( ${__installed_jq_sha256} )

  __installed_jq_sha256=${__installed_jq_sha256[0]}

  [ "${__sha256sum}" = "${__installed_jq_sha256}" ] || {
    >&2 echo -e 'sha256 hash sum('${__installed_jq_sha256}') of the installed '${redbold}${__jq_path}${red}' file does not equal to official '${__sha256sum};
    return 1;
  }

  chmod +x "${__jq_path}" || {
    return 1;
  }

  return 0
}