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

function install_snap_pkg_manager() {  
  snap --version > /dev/null 2>&1 && return 0 # check snap`s existence
  local __distr_name=
  __distr_name=$(. /etc/os-release;echo $ID) # get distributive name
  local __failed=1  
  while true
  do
    case $__os_name in
      ubuntu)
        sudo apt update || break
        sudo apt install snapd && __failed=0
        ;;
      manjaro)
        sudo pacman -S snapd || break
        sudo systemctl enable --now snapd.socket || break
        sudo systemctl enable --now snapd.service || break
        sudo ln -s /var/lib/snapd/snap /snap || break        
        sudo systemctl start snapd.socket || break
        sudo systemctl restart snapd.service && __failed=0
        ;;
      *)
        echo "snapd installation in ${__os_name} is not yet implemented"
        ;;
    esac
    break
  done
  return $__failed
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
    echo -e ''${nocolor}'
This script will install '${green}'snap'${nocolor}' package manager:

  * Documentation: https://snapcraft.io/docs    
'
    user_input_confirmation_default_yes \
      ''${nocolor}'Are you sure you want to install and setup '${green}'snap'${nocolor}' package manager?' \
      || { __funccanceled=1 ; break; }

    install_snap_pkg_manager || break

    __funcresult=0
    break
  done  
  
  cd "$old_dir"

  while true
  do
    [ $__funccanceled -eq 1 ] \
        && { echo -e "${red}snap installation is canceled${nocolor}" 1>&2 ; break; }

    [ ! -z "$__funcerror" ] \
        && { echo -e "${red}${__funcerror}${nocolor}" 1>&2 ; __funcresult=1 ; break; }
    
    [ $__funcresult -eq 0 ] \
        && { echo -e "${green}snap installation is succeeded${nocolor}" ; break; }
        
    echo -e "${red}snap installation is failed${nocolor}" 1>&2
    
    break
  done

  exit $__funcresult
}
main $@