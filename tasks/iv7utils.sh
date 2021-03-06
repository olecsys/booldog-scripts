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

Make difference between two '${nocolorbold}'Integra Video'${nocolor}' mems files

Options:
  -p, --current    string    Current '${nocolorbold}'Integra Video mems'${nocolor}' file
  -c, --previous   string    Previous '${nocolorbold}'Integra Video mems'${nocolor}' file
  -k, --key        string    Key '${nocolorbold}'Integra Video mems'${nocolor}' file with additional information
  -f, --flags      string    Various flags for the processing two mems files, delimiter is `,`
Flags:
  all                        Show all lines
  size-value-increased       Show lines with the increased value of a size
  count-value-increased      Show lines with the increased value of a count
  size-value-decreased       Show lines with the decreased value of a size
  count-value-decreased      Show lines with the decreased value of a count
  size-value-unchanged       Show lines with the unchanged value of a size
  count-value-unchanged      Show lines with the unchanged value of a count
  sort-by-count              Sort lines by count'
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

  local i __previous= __current= __key_filename= __flags=
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
      --key|-k)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __key_filename=${__args[i]}
        ;;
      --flags|-f)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __flags=${__args[i]}
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
    >&2 echo -e ${nocolor}'
cannot find required option: '${nocolorbold}'-p|--previous'${nocolor}'

See `'${nocolorbold}${__script_name}${nocolor}' help diff`.';
    return 1;
  }
  [ -f "${__current}" ] || {
    >&2 echo -e ${nocolor}'
cannot find '${nocolorbold}${__current}${nocolor}' that is passed through required option: '${nocolorbold}'-c|--current'${nocolor}'

See `'${nocolorbold}${__script_name}${nocolor}' help diff`.';
    return 1;
  }
  [ -f "${__previous}" ] || {
    >&2 echo -e ${nocolor}'
cannot find '${nocolorbold}${__previous}${nocolor}' that is passed through required option: '${nocolorbold}'-p|--previous'${nocolor}'

See `'${nocolorbold}${__script_name}${nocolor}' help diff`.';
    return 1;
  }

  local __size_increased= __count_increased=
  local __size_decreased= __count_decreased=
  local __size_unchanged= __count_unchanged=
  local __all=
  local __sort_by_count=
  [ -z "${__flags}" ] && {
    __all='all'
  } || {
    IFS=','
    local __flags=( ${__flags} )
    for ((i=0; i<${#__flags[@]}; i++))
    do
      case ${__flags[i]} in
        size-value-increased)
          __size_increased="${__flags[i]}"
          ;;
        count-value-increased)
          __count_increased="${__flags[i]}"
          ;;
        size-value-decreased)
          __size_decreased="${__flags[i]}"
          ;;
        count-value-decreased)
          __count_decreased="${__flags[i]}"
          ;;
        size-value-unchanged)
          __size_unchanged="${__flags[i]}"
          ;;
        count-value-unchanged)
          __count_unchanged="${__flags[i]}"
          ;;
        sort-by-count)
          __sort_by_count="${__flags[i]}"
          ;;
        all)
          __all="${__flags[i]}"
          ;;
        *)
          >&2 echo -e ${nocolor}'unknown flag that is passed through option '${nocolorbold}'-f|--flags'${nocolor}': '${__flags[i]}'

See `'${nocolorbold}${__script_name}${nocolor}' help diff`.'
          return 1
          ;;
      esac
    done
  }

  [ -z "${__all}" ] || {
    __size_increased='size-value-increased' __count_increased='count-value-increased'
    __size_decreased='size-value-decreased' __count_decreased='count-value-decreased'
    __size_unchanged='size-value-unchanged' __count_unchanged='count-value-unchanged'
  }

  local __sort_column='-k3'
  [ -z "${__sort_by_count}" ] || {
    __sort_column='-k2'
  }

  local __processed_current=$(grep '^[\[0-9]\+].*' "${__current}"\
    |sed 's/^\(\[[0-9]\+\]\)\s\+cnt=\([0-9]\+\)\s\+sz=\([0-9]\+\)/\1 \2 \3/'\
    |sort ${__sort_column} -n -r)

  IFS=$'\n'
  local __processed_ids=( $(echo "${__processed_current}"\
    |sed 's/^\[\([0-9]\+\)\].*/\1/') )
  
  local __processed_cnts=( $(echo "${__processed_current}"\
    |sed 's/^.*\s\+\([0-9]\+\)\s\+\([0-9]\+\).*/\1/') )

  local __processed_szs=( $(echo "${__processed_current}"\
    |sed 's/^.*\s\+\([0-9]\+\)\s\+\([0-9]\+\).*/\2/') )

  local __processed_current=( $(grep '^[\[0-9]\+].*' "${__previous}"\
    |sed 's/^\[\([0-9]\+\)\]\s\+cnt=\([0-9]\+\)\s\+sz=\([0-9]\+\).*/\1;\2;\3/') )  

  IFS=';'
  local i
  declare -A local __prev_map
  for ((i=0; i<${#__processed_current[@]}; i++))
  do
    local value=( ${__processed_current[i]} )
    local key=${value[0]}
    __prev_map[${key}]="${value[1]};${value[2]}"
  done

  declare -A local __keys_map
  if ! [ -z "${__key_filename}" ] && [ -f "${__key_filename}" ]; then
    local __processed_current=
    mapfile -t __processed_current < "${__key_filename}"

    IFS=']'
    local i= __value= __key=
    for i in "${__processed_current[@]}"
    do
      __value=( ${i} )
      __key=${__value[0]:1}
      __keys_map[${__key}]="${__value[1]}"
    done
  fi

  IFS=';'
  local i= __id= __cnt= __sz= __additional_info= __prev_cnt= __prev_sz=
  local __sz_diff_text= __cnt_diff_text= __sz_diff= __cnt_diff= __skip=
  for ((i=0; i<${#__processed_ids[@]}; ++i))
  do
    __id=${__processed_ids[i]}
    __cnt=${__processed_cnts[i]}
    __sz=${__processed_szs[i]}

    __additional_info=''
    [ ${__keys_map[${__id}]+_} ] && {
      __additional_info=": ${__keys_map[${__id}]}"
    }
    
    __prev_cnt=0 __prev_sz=0
    [ ${__prev_map[${__id}]+_} ] && {
      __value=( ${__prev_map[${__id}]} )
      __prev_cnt="${__value[0]}"
      __prev_sz=${__value[1]}
    }

    __sz_diff_text=''
    __cnt_diff_text=''
    __sz_diff=
    __cnt_diff=
    __sz_diff=$(($__sz-$__prev_sz))
    __cnt_diff=$(($__cnt-$__prev_cnt))

    __skip=1
    if [ ${__sz_diff} -gt 0 ]; then
      __sz_diff_text="(+${__sz_diff})"
      [ -z "${__size_increased}" ] || {
        __skip=0
      }
    elif [ ${__sz_diff} -lt 0 ]; then
      __sz_diff_text="(${__sz_diff})"
      [ -z "${__size_decreased}" ] || {
        __skip=0
      }
    else
      [ -z "${__size_unchanged}" ] || {
        __skip=0
      }
    fi
    
    if [ ${__cnt_diff} -gt 0 ]; then
      __cnt_diff_text="(+${__cnt_diff})"
      [ -z "${__count_increased}" ] || {
        __skip=0
      }
    elif [ ${__cnt_diff} -lt 0 ]; then
      __cnt_diff_text="(${__cnt_diff})"
      [ -z "${__count_decreased}" ] || {
        __skip=0
      }
    else
      [ -z "${__count_unchanged}" ] || {
        __skip=0
      }
    fi
    if [ ${__skip} -eq 1 ]; then
      continue
    fi

    echo "[${__id}] cnt=${__cnt}${__cnt_diff_text} sz=${__sz}${__sz_diff_text}${__additional_info}"
  done
  return 0;
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