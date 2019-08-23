#!/usr/bin/env bash

function check_variable_existence() {
  [ -z ${1+abc} ] && return 1 || return 0
}

function check_existence_in_array() {
  local __key=$1
  local -a __array=("${!2}")

  local i
  for ((i=0; i<${#__array[@]}; i++))
  do
    [ "${__array[i]}" = "$__key" ] && return 0
  done
  return 1
}

function flickr_photos_search() {
  local old_dir="`pwd`/`basename "$0"`"
  old_dir=`dirname "$old_dir"`
  cd "`dirname "$0"`"
  local script_dir="`pwd`/`basename "$0"`"
  script_dir=`dirname "$script_dir"`
  cd "$old_dir"

  # https://www.flickr.com/services/api/explore/flickr.photos.search
  # https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=FLICKR_API_KEY&user_id=&tags=&tag_mode=&text=motorbike&min_upload_date=&max_upload_date=&min_taken_date=&max_taken_date=&license=&sort=&privacy_filter=&bbox=&accuracy=&safe_search=&content_type=&machine_tags=&machine_tag_mode=&group_id=&contacts=&woe_id=&place_id=&media=&has_geo=&geo_context=&lat=&lon=&radius=&radius_units=&is_commons=&in_gallery=&is_getty=&extras=&per_page=25&page=2&format=json&nojsoncallback=1
  local __method=flickr.photos.search
  local __api_url=https://www.flickr.com/services/rest/?method

  check_variable_existence $1 || { 
    >&2 echo -e 'Please pass '${redbold}'`api_key`'${red}' as first parameter of the '${redbold}'`flickr_photos_search`'${red}' function.';
    return 1;
  }
  local __api_key=${1}
  local __params_name=(
    "user_id" "tags" "tag_mode" "text" "min_upload_date" "max_upload_date"
    "min_taken_date" "max_taken_date" "license" "sort" "privacy_filter"
    "bbox" "accuracy" "safe_search" "content_type" "machine_tags"
    "machine_tag_mode" "group_id" "contacts" "woe_id" "place_id"
    "media" "has_geo" "geo_context" "lat" "lon" "radius" "radius_units"
    "is_commons" "in_gallery" "is_getty" "extras" "per_page" "page"
  )  

  local __url=${__api_url}'='${__method}'&api_key='${__api_key}

  check_variable_existence $2 && {
    local __delim='='
    check_variable_existence $3 && __delim=${3}

    local __IFS_OLD=${IFS}
    IFS=

    local -a __params=("${!2}")
        
    [ -z "${__delim}" ] && local __delim_string=' ' || local __delim_string=${__delim}
    local i
    for ((i=0; i<${#__params[@]}; i++))
    do
      IFS="${__delim}"
      local __param=( ${__params[i]} )
      IFS=${__IFS_OLD}

      [ ! ${#__param[@]} -eq 2 ] && {
        >&2 echo -e 'Bad param '${redbold}'`'${__params[i]}'`'${red}'. Format is: NAME'${__delim_string}'VALUE.';
        return 1;
      }
      check_existence_in_array ${__param[0]} __params_name[@] || {
        >&2 echo -e 'Unknown param '${redbold}'`'${__param[0]}'`'${red}'.';
        return 1;
      }
      local __param_value=${__param[1]}
      __url=${__url}'&'${__param[0]}'='${__param_value}
    done    
  }
  IFS=${__IFS_OLD}

  __url=${__url}'&format=json&nojsoncallback=1'

  check_variable_existence $4 \
    && local __backend=${4} \
    || local __backend=

  . "${script_dir}/../network.sh"

  [ "$(type -t network_get_data)" = function ] || {
    >&2 echo -e 'Shell function '${redbold}'`network_get_data`'${red}' does not exist.';
  }

  IFS=
  local __output=
  __output=$(network_get_data ${__url} 1 "${__backend}") || {    
    >&2 echo -e "${__output}";
    IFS=${__IFS_OLD}
    return 1;
  }  
  echo -e "${__output}"
  IFS=${__IFS_OLD}
  return 0
}