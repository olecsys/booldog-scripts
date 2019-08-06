#!/bin/bash
function read_options() {
  g_opt_ind=0
  while getopts "yYnN" opt; do
    glob_opt_args[$g_opt_ind]=$opt
    g_opt_ind=$(($g_opt_ind+1))
  done
  g_opt_ind=0
}

function user_input_confirmation_default_yes() {
  local __question=$1

  local __text=$(echo -e "${__question} (Y/n)")
  read -p "${__text}" -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]] && return 0 || return 1
}

function check_existence_in_array() {
    local __key=$1
    local -a __array=("${!2}")

    for ((i=0; i<${#__array[@]}; i++))
    do
        [ "${__array[i]}" = "$__key" ] && return 0
    done
    return 1
}

function main() {
  local old_dir="`pwd`/`basename "$0"`"
  old_dir=`dirname "$old_dir"`
  cd "`dirname "$0"`"
  local script_dir="`pwd`/`basename "$0"`"
  script_dir=`dirname "$script_dir"`
  cd "$old_dir"

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'

  local __cmd_args=( "$@" )

  read_options $@  

  local __funcerror=     # set `__funcerror` variable with custom error message 
  local __funccanceled=0 # if you want to cancel script set to `1`
  local __funcresult=1   # set `__funcresult` variable with script result

  while true
  do
    local supported_distros=( "ubuntu" )

    local __distr_name=
    __distr_name=$(. /etc/os-release;echo $ID) # get distributive name
    
    check_existence_in_array "$__distr_name" supported_distros[@] \
        || { __funcerror="
${__distr_name} ${green}X2Goserver${red} installation is not yet implemented
" ; break; }

    echo -e ''${nocolor}'
This script will install '${green}'X2Goserver'${nocolor}' remote access server:

  * Documentation: https://wiki.x2go.org/doku.php
'

    user_input_confirmation_default_yes \
        'Are you sure you want to install and setup '${green}'X2Goserver'${nocolor}'?' \
        || { __funccanceled=1 ; break; }

    case $__distr_name in
      ubuntu)
        sudo apt-get update || break
        sudo apt-get install software-properties-common || break
        sudo add-apt-repository ppa:x2go/stable || break
        sudo apt-get update || break
        sudo apt-get install x2goserver x2goserver-xsession || break        
        ;;
    esac

    sudo sed -i \
      's/^[#]*X11Forwarding\s\+.*$/X11Forwarding yes/' \
      /etc/ssh/sshd_config || break

    __funcresult=0
    break
  done  
  
  cd "$old_dir"

  while true
  do
    [ $__funccanceled -eq 1 ] \
        && { echo -e "${red}X2Goserver installation is canceled${nocolor}" 1>&2 ; break; }

    [ ! -z "$__funcerror" ] \
        && { echo -e "${red}${__funcerror}${nocolor}" 1>&2 ; __funcresult=1 ; break; }
    
    [ $__funcresult -eq 0 ] \
        && { echo -e "${green}X2Goserver installation is succeeded${nocolor}" ; break; }
        
    echo -e "${red}X2Goserver installation is failed${nocolor}" 1>&2
    
    break
  done

  exit $__funcresult
}
main $@