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

set -o errexit
#set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

# Get API key
source mapquest.key

# DESC: Print Location info.
# ARGS: $1 (required): Array of location info. 
#       $2 (optional): Exit code (defaults to 1)
function print_location_info(){

	info=$1

	#info=$(echo ${query} | jq -r '.results[0].locations[0] | {adminArea5, adminArea3, adminArea1}[], .latLng[]')

	# Setting up Location variables
	CITY=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea5')
	STATE=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea3')
	COUNTRY=$(echo ${info} | jq -r '.results[0].locations[0] | .adminArea1')
	#ZIPCODE=${info_arr[3]}
	LATITUDE=$(echo ${info} | jq -r '.results[0].locations[0] | .latLng.lat')
	LONGITUDE=$(echo ${info} | jq -r '.results[0].locations[0] | .latLng.lng')

	# Print 
	echo -e "
		\rThe location of ${addr} is:
		\rCity: \t\t${CITY}
		\rState: \t\t${STATE}
		\rCountry: \t${COUNTRY}
		\rLatitude: \t${LATITUDE}
		\rLongitude: \t${LONGITUDE}
	"
	exit 1
}

url='https://www.mapquestapi.com/geocoding/v1/address?key='
args='&location='
converter="${url}${key}${args}"
addr="$(echo $* | sed 's/ /+/g')" 

query=$(curl -s "${converter}${addr}") 

print_location_info "${query}"
exit 0
