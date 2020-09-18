#!/usr/bin/env bash

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

function get_script_name() {
  [ ! -z "${BASH_SOURCE[0]}" ] && {
    echo $(basename "${BASH_SOURCE[0]}")
    return 0
  }
  echo $(basename "$0")
  return 0
}

function user_input_confirmation_default_yes() {
  local __question=$1

  local __text=$(echo -e "${__question} (Y/n)")
  read -p "${__text}" -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]] && return 0 || return 1
}

function main() {
  local __old_dir=$(pwd)
  __old_dir=$(realpath "${__old_dir}")
  local __script_name= __script_dir=
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)


  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local __funcmsg=       # set `__funcerror` variable with custom message 
  local __funccanceled=0 # if you want to cancel script set to `1`
  local __funcresult=1   # set `__funcresult` variable with script result
  local __software_name="booldog-scripts"
  
  while true
  do 
    user_input_confirmation_default_yes \
      ''${nocolor}'Are you sure you want to install/update '${nocolorbold}${__software_name}${nocolor}'?' \
      || { __funccanceled=1 ; break; }

    local booldog_scripts_directory="${HOME}/.booldog-scripts"
    [ -d "$booldog_scripts_directory" ] || {
      __funcmsg=$(mkdir -p "$booldog_scripts_directory" 2>&1) || {
        __funcmsg=${redbold}${__funcmsg}
        break
      }
    }
    __funcmsg=$(cp "${__script_dir}/../json.sh" "${booldog_scripts_directory}/" 2>&1) || {
      __funcmsg=${redbold}${__funcmsg}
      break
    }
    __funcmsg=$(cp "${__script_dir}/../network.sh" "${booldog_scripts_directory}/" 2>&1) || {
      __funcmsg=${redbold}${__funcmsg}
      break
    }

    __funcresult=0
    break
  done  
  
  cd "${__old_dir}"

  while true
  do
    [ ! -z "$__funcmsg" ] && {
      [ $__funcresult -eq 0 ] && {
        echo -e "${__funcmsg}${nocolor}"

      } || {
        echo -e "${__funcmsg}${nocolor}" 1>&2
      }
      break
    }

    [ $__funccanceled -eq 1 ] && {
      echo -e ${redbold}${__script_name}${red}' is canceled'${nocolor} 1>&2
      break
    }   
    
    [ $__funcresult -eq 0 ] || {        
      echo -e ${redbold}${__script_name}${red}' is failed'${nocolor} 1>&2
    }
    break
  done

  [ "${BASH_SOURCE[0]}" = "$0" ] && {
    exit $__funcresult
  } || {
    return $__funcresult
  }  
}
main "$@"