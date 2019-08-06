#!/bin/bash
function read_options() {
  g_opt_ind=0
  while getopts "yYnN" opt; do
    glob_opt_args[$g_opt_ind]=$opt
    g_opt_ind=$(($g_opt_ind+1))
  done
  g_opt_ind=0
}

function check_executable_exists() {
  command -v "$1" > /dev/null 2>&1
}

function user_input_confirmation_default_yes() {
  local __question=$1

  local __text=$(echo -e "${__question} (Y/n)")
  read -p "${__text}" -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]] && return 0 || return 1
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
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local __cmd_args=( "$@" )

  read_options $@  

  local __funcerror=     # set `__funcerror` variable with custom error message 
  local __funccanceled=0 # if you want to cancel script set to `1`
  local __funcresult=1   # set `__funcresult` variable with script result

  while true
  do
    local __software_name=Docker

    # check docker`s existence
    check_executable_exists docker \
      && { __funcresult=0 ; break; }

    # check snap`s existence
#     check_executable_exists snap \
#       || { __funcerror='
# '${redbold}${__software_name}${red}' installation requires '${redbold}'snap'${red}' package manager.
# Please install it first.

#   * Documentation: https://snapcraft.io/docs
# ' ; break; }

    echo -e ''${nocolor}'
This script will install '${nocolorbold}${__software_name}${nocolor}':

  * Documentation: https://www.docker.com
'
    user_input_confirmation_default_yes \
      ''${nocolor}'Are you sure you want to install and setup '${nocolorbold}${__software_name}${nocolor}'?' \
      || { __funccanceled=1 ; break; }

    sudo groupadd docker > /dev/null 2>&1

    sudo usermod -aG docker $USER

    sudo pacman -S docker || break

    sudo systemctl start docker || break
    sudo systemctl enable docker || break

    __funcresult=0
    break
  done  
  
  cd "$old_dir"

  while true
  do
    [ $__funccanceled -eq 1 ] \
        && { echo -e '
'${redbold}${__software_name}${red}' installation is canceled
'${nocolor} 1>&2 ; break; }

    [ ! -z "$__funcerror" ] \
        && { echo -e "
${red}${__funcerror}${nocolor}
" 1>&2 ; __funcresult=1 ; break; }
    
    [ $__funcresult -eq 0 ] \
        && { echo -e '
'${greenbold}${__software_name}${green}' installation is succeeded
'${nocolor} ; break; }
        
    echo -e '
'${redbold}${__software_name}${red}' installation is failed
'${nocolor} 1>&2
    
    break
  done

  exit $__funcresult
}
main $@