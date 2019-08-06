#!/bin/bash
function read_options() {
  g_opt_ind=0
  while getopts "yYnN" opt; do
    glob_opt_args[$g_opt_ind]=$opt
    g_opt_ind=$(($g_opt_ind+1))
  done
  g_opt_ind=0
}

function main() {
  local old_dir="`pwd`/`basename "$0"`"
  old_dir=`dirname "$old_dir"`
  cd "`dirname "$0"`"
  local script_dir="`pwd`/`basename "$0"`"
  script_dir=`dirname "$script_dir"`
  cd "$old_dir"
  read_options $@

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'

  __funcerror=
  __funccanceled=0
  __funcfailed=0


  # mkdir -p $HOME/.ssh || __funcfailed=1
  # ssh-keygen -t rsa -b 4096 -C "$GIT_USER_EMAIL" -f "$GIT_PROJECT_DIR/YOURRSA" || __funcfailed=1

  if [ $__funcfailed -eq 0 ] && [ $__funccanceled -eq 0 ]; then
    # cat "${script_dir}/../test"|xargs -I R echo R
    # s/^host.*$\nHostName iv\..*$\nIdentify.*$/TEST\nJOKE/
    sed '/^host.*$/{
            $!{ N
            s/^host.*$/TEST\nJOKE/
            t sub-yes
            :sub-not
            P
            D
            :sub-yes
            }
        }' "${script_dir}/../multiline-test"
    # echo "Some action" || __funcfailed=1
  fi

  if [ $__funccanceled -eq 1 ]; then
    echo -e "${red}Script process name is canceled${nocolor}" 1>&2
  else
    if [ $__funcfailed -eq 0 ]; then
      echo -e "${green}Script process name is succeeded${nocolor}"
    else
      if ! [ -z "$__funcerror" ]; then
        echo -e "${red}$__funcerror${nocolor}" 1>&2
      else
        echo -e "${red}Script process name is failed${nocolor}" 1>&2
      fi
    fi
  fi
  cd "$old_dir"
}
main $@
if [ $__funcfailed -eq 0 ]; then
  exit 0
else
  exit 1
fi