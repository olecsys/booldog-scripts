#!/usr/bin/env bash

function main() {
  local old_dir="`pwd`/`basename "$0"`"
  old_dir=`dirname "$old_dir"`
  cd "`dirname "$0"`"
  local script_dir="`pwd`/`basename "$0"`"
  script_dir=`dirname "$script_dir"`
  cd "$old_dir"

  . "$script_dir/../rest-api/flickr.sh"

  local red='\e[0;31m'
  local green='\e[0;32m'
  local nocolor='\e[0m'
  local redbold='\e[1;31m'
  local greenbold='\e[1;32m'
  local nocolorbold='\e[1m'

  local __funcerror=     # set `__funcerror` variable with custom error message
  local __funcresult=1   # set `__funcresult` variable with script result

  while true
  do
    [ "$(type -t flickr_photos_search)" = function ] || {
      __funcerror=$(echo -e 'Shell function '${redbold}'`flickr_photos_search`'${red}' does not exist.');
      break;
    }

    local __params_delim='+'
    IFS='|'
    local __params0=(
      "text+motorbike" "extras+url_c,owner_name"
    )

    local __api_key=${FLICKR_API_KEY}

    local __output0=
    __output0=$(flickr_photos_search ${__api_key} \
      __params0[@] \
      "${__params_delim}" \
      "curl" 2>&1) || {
      __funcerror="${__output0}"
      break
    }

    local __output1=
    __output1=$(flickr_photos_search ${__api_key} \
      __params0[@] \
      "${__params_delim}" \
      "wget" 2>&1) || {
      __funcerror="${__output1}"
      break
    }

    [ "${__output0}" = "${__output1}" ] || {
      __funcerror=$(echo -e ${redbold}'`curl`'${red}' response does not equal to '${redbold}'`wget`'${red}' response.'${__output1});
      break;
    }

    __funcresult=0
    break
  done  
  
  cd "$old_dir"

  while true
  do
    [ ! -z "$__funcerror" ] \
        && { echo -e "
${red}${__funcerror}${nocolor}
" 1>&2 ; __funcresult=1 ; break; }
    
    [ $__funcresult -eq 0 ] \
        && { echo -e '
'${greenbold}'rest-api/flickr.sh test'${green}' is succeeded
'${nocolor} ; break; }
        
    echo -e '
'${redbold}'rest-api/flickr.sh test'${red}' is failed
'${nocolor} 1>&2
    
    break
  done

  exit $__funcresult
}
main $@