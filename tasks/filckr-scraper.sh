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
    download)
      echo -e ${nocolor}'
Usage: '${nocolorbold}${__script_name}${nocolor}' '${__command}' [OPTIONS]

Download various '${nocolorbold}'Flickr`s'${nocolor}' content by type

Options:
  -t, --type            string    Content type('${nocolorbold}'image'${nocolor}')
  -d, --dir             string    Download content to this directory
  -s, --search-text     string    Text to search content
  -l, --limit           uint16    Content`s limit(e.g. images count in the '${nocolorbold}'--dir'${nocolor}' directory)'
      ;; 
    *)
      echo -e ${nocolor}'Usage: '${nocolorbold}${__script_name}${nocolor}' COMMAND [OPTIONS]

'${nocolorbold}'Flickr`s'${nocolor}' content SHELL script scraper

Commands:
  download
  help

Run `'${nocolorbold}${__script_name}${nocolor}' --help COMMAND` for more information on a command.'
      
      ;;
  esac  
}

function flickr_scraper_download() {
  local __script_name= __script_dir
  __script_name=$(get_script_name)
  __script_dir=$(get_script_dir)

  local -a __args=("${!1}")

  local i __content_type= __dir="${HOME}/.booldog-scripts/data/flickr" __limit=3000 __search_text=
  for ((i=1; i<${#__args[@]}; i++))
  do
    case ${__args[i]} in
      --type|-t)        
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __content_type=${__args[i]}
        ;;
      --dir|-d)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __dir=${__args[i]}
        ;;
      --limit|-l)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __limit=${__args[i]}
        ;;
      --search-text|-s)
        i=$(expr $i + 1)
        [ ${i} -eq ${#__args[@]} ] && break
        __search_text=${__args[i]}
        ;;
      *)
        >&2 echo -e ${nocolor}'unknown flag: '${__args[i]}'
See `'${nocolorbold}${__script_name}${nocolor}' help download`.'
        return 1
        ;;
    esac
  done
  [ -z "${__content_type}" ] && {
    >&2 echo -e ${nocolor}'cannot find required option: '${nocolorbold}'-t|--type'${nocolor}'
See `'${nocolorbold}${__script_name}${nocolor}' help download`.';
    return 1;
  }
  [ -z "${__search_text}" ] && {
    >&2 echo -e ${nocolor}'cannot find required option: '${nocolorbold}'-s|--search-text'${nocolor}'
See `'${nocolorbold}${__script_name}${nocolor}' help download`.';
    return 1;
  }  

  local __api_key=${FLICKR_API_KEY}

  case $__content_type in
    image)
      . "${__script_dir}/../json.sh"
      . "${__script_dir}/../network.sh"
      . "${__script_dir}/../rest-api/flickr.sh"

      [ "$(type -t flickr_photos_search)" = function ] || {
        >&2 echo -e 'Shell function '${redbold}'`flickr_photos_search`'${red}' does not exist.'
        return 1
      }

      [ "$(type -t json_install_jq)" = function ] || {
        >&2 echo -e 'Shell function '${redbold}'`json_install_jq`'${red}' does not exist.';
        return 1
      }

      [ "$(type -t json_get_jq_path)" = function ] || {
        >&2 echo -e 'Shell function '${redbold}'`json_get_jq_path`'${red}' does not exist.';
        return 1
      }

      [ "$(type -t network_download_file)" = function ] || {
        >&2 echo -e 'Shell function '${redbold}'`network_download_file`'${red}' does not exist.';
      }

      local __jq_path=
      __jq_path=$(json_get_jq_path) || {
        json_install_jq || return 1
      }

      __dir=$(realpath "${__dir}")
      [ -e "${__dir}" ] && [ ! -d "${__dir}" ] && {
        >&2 echo -e 'command line argument '${redbold}'`--dir|-d`'${red}' value '${redbold}'`'${__dir}'`'${red}' is not directory.';
        return 1
      }
      mkdir -p "${__dir}" || return 1

      __dir_photos_count=$(ls "${__dir}"|wc -l)
      [ ${__dir_photos_count} -gt ${__limit} ] && {
        >&2 echo -e 'photos limit in `'${__dir}'` is exceeded.';
        return 1
      }

      local FLICKR_SCRAPER_PAGE=0
      local __page_counter_path="${__dir}/.cache.env"
      [ -f "${__page_counter_path}" ] && {
        eval $(cat "${__page_counter_path}" | sed 's/\s/\\ /g' | sed 's/^/export /')
      }

      local __params_delim='='
      local __flickr_params=(
        "text=${__search_text}" "extras=url_c,owner_name" "page=${FLICKR_SCRAPER_PAGE}"
      )

      local __photos_json=
      __photos_json=$(flickr_photos_search ${__api_key} \
        __flickr_params[@] \
        "${__params_delim}" 2>&1) || {
        >&2 echo -e "${__photos_json}"
        return 1
      }

      local __photos_count=
      __photos_count=$(echo -e "${__photos_json}" \
        |"${__jq_path}" '.photos.photo|length') || {
        >&2 echo -e ${redbold}'`Flickr`'${red}' API method '${redbold}'`flickr.photos.search`'${red}' has unknown format'
      }
      local i
      for ((i=0; i<${__photos_count}; i++))
      do
        local __url=$(echo -e "${__photos_json}" \
         |"${__jq_path}" -r '.photos.photo['${i}'].url_c')
        [ "${__url}" = "null" ] && continue

        local __basename=$(basename "${__url}")
        local __ext="${__basename##*.}"

        __basename=$(echo "${__url}"|sha256sum)
        __basename=( ${__basename} )
        __basename=${__basename[0]}

        __output_file="${__dir}/${__basename}.${__ext}"

        [ -f "${__output_file}" ] && {
          echo ${__output_file}' already exists' > /dev/tty
          continue
        }

        local __funcerror=
        __funcerror=$(network_download_file ${__url} "${__output_file}" 2>&1 >/dev/tty) || {
          >&2 echo -e "${__funcerror}"
          return 1
        }
        __dir_photos_count=$(expr $__dir_photos_count + 1)

        [ ${__dir_photos_count} -gt ${__limit} ] && {
          break
        }

        sleep 3s

      done

      FLICKR_SCRAPER_PAGE=$(expr $FLICKR_SCRAPER_PAGE + 1)
      (
      tee "${__page_counter_path}" > /dev/null <<EOFBOOLDOG
FLICKR_SCRAPER_PAGE=${FLICKR_SCRAPER_PAGE}
EOFBOOLDOG
) || return 1

      ;;
    *)
      >&2 echo -e ${nocolor}'unknown content type: '${__content_type}'
See `'${nocolorbold}${__script_name}${nocolor}' help download`.'
      return 1
      ;;
  esac
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
      download)
        flickr_scraper_download $1 __funccanceled && {
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