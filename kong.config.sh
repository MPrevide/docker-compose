#!/bin/sh -ex

kong="http://apigw:8001"

authService() {

    echo "authConfigService ${1}"

    curl -s  -i -X POST \
    --url ${kong}/services/${1}/plugins/ \
    --data "name=pepkong" \
    --data "config.pdpUrl=http://auth:5000/pdp"

    curl -s  -i -X POST \
    --url ${kong}/services/${1}/plugins/ \
    --data "name=jwt"
}

createService() {
#$1 = Service Name
#$2 = URL (ex.: http://gui:80)
    echo "createService ${1} ${2}"
    curl -s -i -X POST \
    --url ${kong}/services/ \
    --data "name=${1}" \
    --data "url=${2}"
}

createRoute() {
#$1 = Service Name
#$2 = Route Name
#$3 = PATHS (ex.: /,/x)
#$4 = strip_path
    echo "createRoute ${1} ${2} ${3} ${4} "
    curl -s -i -X POST \
    --url ${kong}/services/${1}/routes \
    --data "name=${2}" \
    --data "paths[]=${3}" \
    --data "strip_path=${4}"
}

createService "gui4" "http://gui:80"
createRoute "gui4" "gui_route4" "/" "false"
authService "gui4"


