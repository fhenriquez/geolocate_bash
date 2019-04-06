#!/usr/bin/env bash
#########################################################################
# Name: Franklin Henriquez                                              #
# Author: Franklin Henriquez (franklin.a.henriquez@gmail.com)           #
# Creation Date: 04Apr2019                                              #
# Last Modified: 05Apr2019                                              #
# Description:	Gets location information from mapquest API.			#
#                                                                       #
# Version: 0.1.0                                                        #
#                                                                       #
#########################################################################

#set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

# Get API key
source mapquest.key

# DESC: Generic script initialisation
# ARGS: None
function script_init() {
    # Useful paths
    readonly orig_cwd="$PWD"
    readonly script_path="${BASH_SOURCE[0]}"
    readonly script_dir="$(dirname "$script_path")"
    readonly script_name="$(basename "$script_path")"

    # Important to always set as we use it in the exit handler
    readonly ta_none="$(tput sgr0 || true)"
}

# DESC: Usage help
# ARGS: None
function usage() {
    echo -e "
    \rUsage: ${__base} \"location\" [options]
    \rDescription:\t Gathers location information given a named location.

    \rrequired arguments:
    \r<location>\tLocation name.

    \roptional arguments:
    \r-c|--coordinates\tOnly print coordinates Lat and Lng.
    \r-h|--help\t\tShow this help message and exit.
    \r-u|--url\t\tPrint URL for MapQuest. 
    "
}

# DESC: Print Location info.
# ARGS: $1 (required): Array of location info as json. 
#       $2 (optional): Exit code (defaults to 0)
function print_location_info(){

	info=$1

	# Setting up Location variables
	CITY=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea5')
	STATE=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea3')
	COUNTRY=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea1')
	#ZIPCODE=${info_arr[3]}
	LATITUDE=$(echo ${info} | jq -r '.results[0].locations[0] | .latLng.lat')
	LONGITUDE=$(echo ${info} | jq -r '.results[0].locations[0] | .latLng.lng')
	MAPURL=$(echo ${info} | jq -r '.results[0].locations[0] | .mapUrl')

	# Print 
	if [[ ${coordinates} -eq 1 ]]
	then
		echo -e "\
			\rLatitude: \t${LATITUDE}
			\rLongitude: \t${LONGITUDE}"
	elif [[ ${mapurl} -eq 1 ]]
	then
		echo -e "\
			\rMapUrl: ${MAPURL}"
	else
		echo -e "\
			\rThe location of ${addr} is:
			\rCity: \t\t${CITY}
			\rState: \t\t${STATE}
			\rCountry: \t${COUNTRY}
			\rLatitude: \t${LATITUDE}
			\rLongitude: \t${LONGITUDE}
			\rMapUrl: \t${MAPURL}"
	fi
	return 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        params=$(echo ${1})

        shift
        # Iterate through all the parameters.
        for param in $(echo ${params})
        do
            case $param in
                -c|--coordinates)
                    coordinates=1
                    ;;
               -h|--help)
                    usage
                    exit 0
                    ;;
               -u|--url)
                    mapurl=1
                    ;;
                -*)
                    usage
                    echo -e "${IYellow}Invalid Parameter${Color_Off}:"
                    "\r ${IRed}${param}${Color_Off}"
                    exit 0
                    ;;
                *)
					usage
                    exit 0
                    ;;
                esac
        done
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
function main() {
    # shellcheck source=source.sh
    #source "$(dirname "${BASH_SOURCE[0]}")/bash_color_codes"

    #trap "script_trap_err" ERR
    #trap "script_trap_exit" EXIT

    script_init
    #colour_init

    # Print usage if no parameters are entered.
    if [ $# -eq 0 ]
    then
        usage
        exit 2
    fi
	
	mapurl=0
	coordinates=0

	get_params="$@"
    sorted_params=$( echo ${get_params} | tr ' ' '\n' | grep '-' | sort | tr '\n' ' ' | sed 's/ *$//')
    parse_params "${sorted_params}"

    query=$( echo ${get_params} | tr ' ' '\n' | grep -v '-') 
	api='https://www.mapquestapi.com/geocoding/v1/address?key='
	args='&location='
	converter="${api}${key}${args}"
	addr="$(echo $* | sed 's/ /+/g')" 

	resp=$(curl -s "${converter}${addr}") 
	
	print_location_info "${resp}"
	exit 0
}

# Start main function
main "$@"
