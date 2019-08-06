#!/bin/bash

# gvfs-smb for samba shared directories in pcmanfm

function read_options() {
  g_opt_ind=0
  while getopts "yYnN" opt; do
    glob_opt_args[$g_opt_ind]=$opt
    g_opt_ind=$(($g_opt_ind+1))
  done
  g_opt_ind=0
}

function find_os_package_manager() {
  local __package_manager=$1
  local __package_manager_install=$2

  local __pkg_manager=
  local __pkg_manager_inst=

  while true
  do  
    local __pkg_manager=pacman ; ${__pkg_manager} --version > /dev/null 2>&1 \
      || __pkg_manager=
    [ -z "${__pkg_manager}" ] || break

    local __pkg_manager=apt-get ; ${__pkg_manager} --version > /dev/null 2>&1 \
      || __pkg_manager=
    [ -z "${__pkg_manager}" ] || break
    
    break
  done

  eval $__package_manager="'$__pkg_manager'"
  eval $__package_manager_install="'$__pkg_manager_inst'"

  [ -z "${__pkg_manager}" ] && return

  case $__pkg_manager in
  pacman)
    __pkg_manager_inst=${__pkg_manager}\ -S
    ;;
  apt-get|apt)
    __pkg_manager_inst=${__pkg_manager}\ install
    ;;
  *)
    echo ""
    ;;
  esac
  eval $__package_manager_install="'$__pkg_manager_inst'"
}

function user_input_options() {
  local __question=$1
  local -a __options=("${!2}")
  local __resultvar=$3

  PS3="$__question"
  select opt in "${__options[@]}"
  do    
    local __exists=0 ; local __index=$(expr $REPLY - 1) ; \
      [ ${__options[$__index]+abc} ] && __exists=1 || __exists=0
    eval $__resultvar="'$opt'"    
    [ $__exists -eq 1 ] && break || echo "invalid option $REPLY"
  done
}

function user_input_autocompletion() {
  local __question=$1
  local __resultvar=$2

  local __user_input=
  while true
  do
    read -e -p "${__question}" __user_input
    [ -z "${__user_input}" ] || break
  done
  eval $__resultvar="'$__user_input'"
}

function user_input_confirmation_default_yes() {
  local __question=$1

  read -p "${__question} (Y/n) " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]] && return 0 || return 1
}

function user_input_confirmation_default_no() {
  local __question=$1

  read -p "${__question} (y/N) " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]] && return 0 || return 1
}

function install_snap_pkg_manager() {  
  snap --version > /dev/null 2>&1 && return 0 # check snap`s existence
  echo ''
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

function install_snap_packages() {  
  local __snap_packages_path=${1}

  local __line=  
  while IFS= read -r __line || [ -n "$__line" ]
  do
    sudo snap install ${__line} || return 1
  done < "$__snap_packages_path"

  return 0
}


function is_root() {
  [ "$UID" -eq 0 ] && return 0 || return 1
}

function os_name() {
  local __resultvar=$1
  local __os_name=
  __os_name=$(. /etc/os-release;echo $ID)
  eval $__resultvar="'$__os_name'"
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

  local __funcerror=
  local __funccanceled=0
  local __funcfailed=1

  while true
  do
    install_snap_pkg_manager || break

    # local profiles=$()
    local profiles=($(ls ${script_dir}/os-configure-profiles))

    local profile
    user_input_options 'Please select os-configure profile: ' profiles[@] profile
    echo
    # echo $res
   


    local snap_packages_path="${script_dir}/os-configure-profiles/${profile}/packages/snap/requirements.txt"
    [ -e "${snap_packages_path}" ] || snap_packages_path=

    if ! [ -z "${snap_packages_path}" ]; then
      local packages=$(cat "${snap_packages_path}"|xargs -I R echo "* R")
      user_input_confirmation_default_yes "You have a list of the snap packages:
Documentation: https://snapcraft.io/docs      

${packages}

Are you sure you wish to install these snap packages?" || break
    #   install_snap_packages "$snap_packages_path" || break
    fi

    

    local pkg_manager=
    local pkg_manager_inst=
    find_os_package_manager pkg_manager pkg_manager_inst
    echo "$pkg_manager_inst"

    is_root && { echo 'ROOT' ; break; } || echo 'NOT ROOT'

    if [ -z "${pkg_manager}" ]; then
      __funcerror=Cannot\ find\ package\ manager
      __funcfailed=1
      break
    fi

    # input="${script_dir}/../test"
    # while IFS= read -r line || [ -n "$line" ]
    # do
    #   echo "$line"
    # done < "$input"

    # local mydir=
    # user_input_autocompletion 'Enter directory: ' mydir
    # echo ${mydir}

    read -p 'Are you sure? (Y/n) ' -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi

    # local res
    # local options=("Option 1" "Option 2" "Option 3" "Quit")  
    # user_input_options 'Please enter your choice: ' options[@] res
    # echo $res

    break
  done  
  
  cd "$old_dir"

  if [ $__funccanceled -eq 1 ]; then
    echo -e "${red}OS configuration is canceled${nocolor}" 1>&2
  else
    if [ $__funcfailed -eq 0 ]; then
      echo -e "${green}OS configuration is succeeded${nocolor}"
    else
      if ! [ -z "$__funcerror" ]; then
        echo -e "${red}${__funcerror}${nocolor}" 1>&2
      else
        echo -e "${red}OS configuration is failed${nocolor}" 1>&2
      fi
    fi
  fi

  if [ $__funcfailed -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
}
main $@