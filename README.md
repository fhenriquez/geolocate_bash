# GeoLocate Bash Script
Gets location information given an address.

## Getting Started
Go to https://developer.mapquest.com/documentation/ and get an API key. 

### Prerequisites

What things you need to install the software and how to install them.

```
awk
curl
jq
sed
```

### Installing

```
git clone git@github.com:fhenriquez/geolocate_bash.git
```


## Usage
```bash
Usage: geolocate "location" [options]
Description:				 Gathers location information given a named location or zip code.

required arguments:
<location>				 Location name.

optional arguments:
-c|--coordinates			 Only print coordinates Lat and Lng.
-h|--help				 Show this help message and exit.
-u|--url				 Print URL for MapQuest (no longer provided by api).
-v, --verbose				 Verbosity.
             					 -v info
             					 -vv debug
             					 -vv bash debug
```

## Contributing

Please read [CONTRIBUTING.md]() for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning


## Authors

* **Franklin Henriquez** - *Initial work* - [fhenriquez](https://github.com/fhenriquez)

See also the list of [contributors]() who participated in this project.

## License

This project is licensed under the GNU General Public License - see the [LICENSE.md](LICENSE.md) file for details


