#!/usr/bin/env bash
#########################################################################
# Name: Franklin Henriquez                                              #
# Author: Franklin Henriquez (franklin.a.henriquez@gmail.com)           #
# Creation Date: 04Apr2019                                              #
# Last Modified: 03Oct2023                                              #
# Description:	Gets location information from mapquest API.			#
#                                                                       #
# Version: 1.0.5                                                        #
#                                                                       #
#########################################################################
# Required binaries:
# - GNU bash 3+
# - getopt
# - jq
# - curl

# Notes:
#
#
__version__="0.1.0"
__author__="Franklin Henriquez"
__email__="franklin.a.henriquez@gmail.com"

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"

# Script Config Vars

# Color Codes
# DESC: Initialize color variables
# ARGS: None
function echo_color_init(){

    Color_Off='\033[0m'       # Text Reset
    NC='\e[m'                 # Color Reset

    # Regular Colors
    Black='\033[0;30m'        # Black
    Red='\033[0;31m'          # Red
    Green='\033[0;32m'        # Green
    Yellow='\033[0;33m'       # Yellow
    Blue='\033[0;34m'         # Blue
    Purple='\033[0;35m'       # Purple
    Cyan='\033[0;36m'         # Cyan
    White='\033[0;37m'        # White

    # Bold
    BBlack='\033[1;30m'       # Black
    BRed='\033[1;31m'         # Red
    BGreen='\033[1;32m'       # Green
    BYellow='\033[1;33m'      # Yellow
    BBlue='\033[1;34m'        # Blue
    BPurple='\033[1;35m'      # Purple
    BCyan='\033[1;36m'        # Cyan
    BWhite='\033[1;37m'       # White

    # High Intensity
    IBlack='\033[0;90m'       # Black
    IRed='\033[0;91m'         # Red
    IGreen='\033[0;92m'       # Green
    IYellow='\033[0;93m'      # Yellow
    IBlue='\033[0;94m'        # Blue
    IPurple='\033[0;95m'      # Purple
    ICyan='\033[0;96m'        # Cyan
    IWhite='\033[0;97m'       # White

}

# Setting up logging
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5
bash_dbg_lvl=6

notify() { log $silent_lvl "${Cyan}NOTE${Color_Off}: $1"; } # Always prints
critical() { log $crt_lvl "${IRed}CRITICAL:${Color_Off} $1"; }
error() { log $err_lvl "${Red}ERROR:${Color_Off} $1"; }
warn() { log $wrn_lvl "${Yellow}WARNING:${Color_Off} $1"; }
info() { log $inf_lvl "${Blue}INFO:${Color_Off} $1"; } # "info" is already a command
debug() { log $dbg_lvl "${Purple}DEBUG:${Color_Off} $1"; }
log() {
    if [ "${verbosity}" -ge "${1}" ]; then
        datestring=$(date +'%Y-%m-%d %H:%M:%S')
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "$datestring - __${FUNCNAME[2]}__  - $2" >&3 #| fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}


logger() {
    if [ -n "${LOG_FILE}" ]
    then
        echo -e "$1" >> "${log_file}"
        #echo -e "$1" >> "${LOG_FILE/.log/}"_"$(date +%d%b%Y)".log
    fi
}

# DESC: What happens when ctrl-c is pressed
# ARGS: None
# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT


function ctrl_c() {
    info "Trapped CTRL-C signal, terminating script"
    log "\n================== $(date +'%Y-%m-%d %H:%M:%S'): Run Interrupted  ==================\n"
    # Any clean up action here
    # rm -f ${TEMP_FILE}
    exit 2
}

# DESC: Usage help
# ARGS: None
function usage() {
    echo -e "
    \rUsage: ${__base} \"location\" [options]
    \rDescription:\t\t\t\t Gathers location information given a named location or zip code.

    \rrequired arguments:
    \r<location>\t\t\t\t Location name.

    \roptional arguments:
    \r-c|--coordinates\t\t\t Only print coordinates Lat and Lng.
    \r-h|--help\t\t\t\t Show this help message and exit.
    \r-l, --log <file>\t\t\t Log file.
    \r-o|--outfile </path/to/outfile> \t CSV outfile.
    \r-u|--url\t\t\t\t Print URL for MapQuest.
    \r-v, --verbose\t\t\t\t Verbosity.
    \r             \t\t\t\t\t -v info
    \r             \t\t\t\t\t -vv debug
    \r             \t\t\t\t\t -vv bash debug
    "
}

# DESC: Parse arguments
# ARGS: main args
function parse_args(){

    local short_opts='c,h,l:,o:,u,v'
    local long_opts='coordinates,help,log:,outfile:,url,verbose'

    #set -x
    # -use ! and PIPESTATUS to get exit code with errexit set
    # -temporarily store output to be able to check for errors
    # -activate quoting/enhanced mode (e.g. by writing out “--options”)
    # -pass arguments only via   -- "$@"   to separate them correctly
    ! PARSED=$(getopt --options=${short_opts} --longoptions=${long_opts} --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # e.g. return value is 1
        #  then getopt has complained about wrong arguments to stdout
        debug "getopt has complained about wrong arguments"
        exit 2
    fi

    # read getopt’s output this way to handle the quoting right:
    eval set -- "$PARSED"

    if [[ "${PARSED}" == " --" ]]
    then
        debug "No arguments were passed"
        usage
        exit 1
    fi

    # Getting positional args
    OLD_IFS=$IFS
    POSITIONAL_ARGS=${PARSED#*"--"}
    IFS=' ' read -r -a positional_args <<< "${POSITIONAL_ARGS}"

    IFS=$OLD_IFS

    # extract options and their arguments into variables.
    while true ; do
        case "$1" in
            -c|--coordinates)
                 coordinates=1
                 ;;
            -h | --help )
                 # Display usage.
                 usage
                 exit 1;
                 ;;
            -l | --log)
                LOG_FILE="$2"
                log_file="${LOG_FILE/.log/}"_"$(date +%d%b%Y)".log
                shift 2
                ;;
            -o | --outfile)
                outfile="$2"
                shift 2
                ;;
            -u|--url)
                 mapurl=1
                 ;;
            -v | --verbose)
               (( verbosity = verbosity + 1 ))
               if [ $verbosity -eq $bash_dbg_lvl ]
               then
                   debug="true"
               fi
               shift
               ;;
            -- )
               shift
               break ;;
            -*)
                usage
                echo -e "${IYellow}Invalid Parameter${Color_Off}:" \
                "${IRed}${param}${Color_Off}"
                exit 0
                ;;
            * )
                usage
                exit 3
        esac
    done

    return 0
}


# DESC: Gets if API key is set.
# ARGS: $@ (required): API key regex variable.
function check_api_key(){

    api_key="${1}"

    # Validate API key regex.
    if [[ "$api_key" =~ ^[0-9a-zA-Z]{32}$ ]]
    then
        debug "The API Key is valid"
        return 0
    else
        # Print line number to check variable.
        variable_line_num=$(grep -n "api_key=" ${__file} | \
            cut -d ':' -f 1 | head -n 1)
        echo -e "Please validate ${Red}API Key${Color_Off}: ${api_key}
                \rReview ${__file} ${IYellow}line number${Color_Off}:" \
                " ${variable_line_num}"

        exit 0
    fi
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


# DESC: main
# ARGS: None
function main(){

    debug="false"
    verbose="false"
    mapurl=0
    coordinates=0

    echo_color_init
    parse_args "$@"

    debug "Starting script"
    debug "
    out_file:        \t ${outfile}
    "

    # Getting from parse_args
    OLD_IFS=$IFS
    IFS=' ' read -r -a pos_args <<< "${POSITIONAL_ARGS[@]}"
    IFS=${OLD_IFS}

    # Run in debug mode, if set
    if [ "${debug}" == "true" ]; then
        set -o noclobber
        set -o errexit          # Exit on most errors (see the manual)
        set -o errtrace         # Make sure any error trap is inherited
        set -o nounset          # Disallow expansion of unset variables
        set -o pipefail         # Use last non-zero exit code in a pipeline
        set -o xtrace           # Trace the execution of the script (debug)
    fi

    # Validating if file is writable
    if [ ! -z "${outfile:-}" ]; then
        debug "Testing destination location for write access"
        touch ${outfile}
    fi

    # Get API key
    apiKey=""

    # Sourcing the api key to keep it private.
    if [ -z "${apiKey}" ]
    then
        debug "Grabbing API Key from file"
        source "${__dir}/mapquest.key"
    fi

    # Check API key.
    check_api_key "${apiKey}"

    # Main

    api='https://www.mapquestapi.com/geocoding/v1/address?key='
    args='&location='
	query="${api}${apiKey}"

    # Positional parameters are validated here.
    pos_arg_count=0
    len=${#pos_args[@]}
    if [[ ${len} == 0 ]]
    then
        debug "No location was passed."
        usage
        exit 1
    else
        while [ $pos_arg_count -lt $len ];
        do
            debug "${pos_args[$pos_arg_count]}"
            location="${pos_args[$pos_arg_count]}"

            location=$(echo ${location} | tr -d "'")
            # If there is a comma, convert to URL friendly format
	        addr="$(echo ${location} | sed 's/ /+/g')"

            resp=$(curl -s "${query}${args}${addr}")

            print_location_info "${resp}"
            pos_arg_count=$((${pos_arg_count}+1))
        done
    fi

}

# make it rain
main "$@"
debug "Script is complete"
exit 0
