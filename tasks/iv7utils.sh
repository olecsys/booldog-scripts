#!/usr/bin/env bash

function check_executable_exists() {
  command -v "$1" > /dev/null 2>&1
}

function check_variable_existence() {
  [ -z ${1+abc} ] && return 1 || return 0
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

function get_script_name() {
  [ ! -z "${BASH_SOURCE[0]}" ] && {
    echo $(basename "${BASH_SOURCE[0]}")
    return 0
  }
  echo $(basename "$0")
  return 0
}

function usage() {
  local __script_name= __script_dir=
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)


  local __command=
  if check_variable_existence $1; then
    local -a __args=("${!1}")
    [ ${#__args[@]} -gt 1 ] && __command=${__args[1]}
  fi

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  case $__command in
    diff)
      echo -e ${nocolor}'
Usage: '${nocolorbold}${__script_name}${nocolor}' '${__command}' [OPTIONS]

Make difference between 2 '${nocolorbold}'Integra Video'${nocolor}' mems files

Options:
  -p, --current            string    Current '${nocolorbold}'Integra Video mems'${nocolor}' file
  -c, --previous           string    Previous '${nocolorbold}'Integra Video mems'${nocolor}' file'
      ;; 
    *)
      echo -e ${nocolor}'Usage: '${nocolorbold}${__script_name}${nocolor}' COMMAND [OPTIONS]

'${nocolorbold}'Integra Video helper'${nocolor}' SHELL script

Commands:
  diff
  help

Run `'${nocolorbold}${__script_name}${nocolor}' --help COMMAND` for more information on a command.'
      
      ;;
  esac  
}

function mems_diff() {
  local __script_name= __script_dir
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)

  local -a __args=("${!1}")

  local i __previous= __current=
  for ((i=1; i<${#__args[@]}; i++))
  do
    case ${__args[i]} in
      --current|-c)        
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __current=${__args[i]}
        ;;
      --previous|-p)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __previous=${__args[i]}
        ;;
      *)
        >&2 echo -e ${nocolor}'unknown flag: '${__args[i]}'
See `'${nocolorbold}${__script_name}${nocolor}' help diff`.'
        return 1
        ;;
    esac
  done
  [ -z "${__current}" ] && {
    >&2 echo -e ${nocolor}'cannot find required option: '${nocolorbold}'-c|--current'${nocolor}'
See `'${nocolorbold}${__script_name}${nocolor}' help diff`.';
    return 1;
  }
  [ -z "${__previous}" ] && {
    >&2 echo -e ${nocolor}'cannot find required option: '${nocolorbold}'-p|--previous'${nocolor}'
See `'${nocolorbold}${__script_name}${nocolor}' help diff`.';
    return 1;
  }  

  
}

function args_parse() {
  local __script_name= __script_dir=
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local -a __args=("${!1}")
  
  local __funccanceled=0
  local __funcresult=0  # set `__funcresult` variable with script result

  local __command=

  [ ${#__args[@]} -eq 0 ] || __command=${__args[0]}

  while true
  do
    case $__command in
      diff)
        mems_diff $1 __funccanceled && {
          __funcresult=0
        } || {
          __funcresult=1
        }
        break
        ;;
      help|--help)
        ;;
      *)
        __funcresult=1      
        ;;
    esac
    [ -z "${__command}" ] && {
      >&2 echo -e ${nocolor}'cannot find: COMMAND
See `'${nocolorbold}${__script_name}${nocolor}' --help`.
'
      usage
    } || {
      usage $1
    }
    break
  done

  check_variable_existence $2 && { 
    local __funccanceled_ref=$2
    eval $__funccanceled_ref="'$__funccanceled'"
  }

  return ${__funcresult}
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

  local __cmd_args=( "$@" )  

  local __funcmsg=       # set `__funcerror` variable with custom message 
  local __funccanceled=0 # if you want to cancel script set to `1`
  local __funcresult=1   # set `__funcresult` variable with script result

  while true
  do  
    __funcmsg=$(args_parse __cmd_args[@] __funccanceled 2>&1) || break

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
    
    [ $__funcresult -eq 0 ] && {
      echo -e ${greenbold}${__script_name}${green}' is succeeded'${nocolor}
    } || {        
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