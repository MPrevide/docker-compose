#!/bin/sh

kong="http://apigw:8001"

#check Kong its ok
if curl --output /dev/null --silent --head --fail "$kong"; then
  echo -e "Kong is started."
else
  echo -e "Kong isn't started."
  echo -e "Terminating..."
  exit 1
fi

addAuthEndpoint() {
#$1 = Service Name
echo -e ""
echo -e ""
echo -e "- addAuthEndpoint: ServiceName=${1}"
curl  -sS  -X POST \
--url ${kong}/services/${1}/plugins/ \
--data "name=pepkong" \
--data "config.pdpUrl=http://auth:5000/pdp"

curl  -sS  -X POST \
--url ${kong}/services/${1}/plugins/ \
--data "name=jwt"
}

createService() {
#$1 = Service Name
#$2 = URL (ex.: http://gui:80)
echo -e ""
echo -e "-- createService: ServiceName=${1} Url=${2}"
curl  -sS -X PUT \
--url ${kong}/services/${1} \
--data "name=${1}" \
--data "url=${2}"
}

createRoute() {
#$1 = Service Name
#$2 = Route Name
#$3 = PATHS (ex.: '"/","/x"')
#$4 = strip_path (true or false)
echo -e ""
echo -e "-- createRoute: ServiceName=${1} Url=${2} PathS=${3} StripPath=${4}"
(curl  ${kong}/services/${1}/routes/${2} -sS -X PUT \
    --header "Content-Type: application/json" \
    -d @- ) <<PAYLOAD
{
    "paths": [${3}],
    "strip_path": ${4}
}
PAYLOAD
}


#ex1: createEndpoint  "data-broker" "http://data-broker:80"  '"/device/(.*)/latest", "/subscription"' "false"
#ex2: createEndpoint "image" "http://image-manager:5000"  '"/fw-image"' "true"
createEndpoint(){
#$1 = Service Name
#$2 = URL (ex.: "http://gui:80")
#$3 = PATHS (ex.: '"/","/x"')
#$4 = strip_path ("true" or "false")
echo -e ""
echo -e ""
echo -e "- createEndpoint: ServiceName=${1} Url=${2} PathS=${3} StripPath=${4}"
createService "${1}" "${2}"
createRoute "${1}" "${1}_route" "${3}" "${4}"
}


createEndpoint "gui" "http://gui:80"  '"/"' "false"

createEndpoint  "data-broker" "http://data-broker:80"  '"/device/(.*)/latest", "/subscription"' "false"
addAuthEndpoint "data-broker"

createEndpoint "data-streams" "http://data-broker:80"  '"/stream"' "true"
addAuthEndpoint "data-streams"

createEndpoint "ws-http" "http://data-broker:80"  '"/socket.io"' "false"

createEndpoint "device-manager" "http://device-manager:5000"  '"/device", "/template"' "false"
addAuthEndpoint "device-manager"

createEndpoint "image" "http://image-manager:5000"  '"/fw-image"' "true"
addAuthEndpoint "image"

createEndpoint "auth-permissions-service" "http://auth:5000/pap"  '"/auth/pap"' "true"
addAuthEndpoint "auth-permissions-service"

createEndpoint "auth-service" "http://auth:5000"  '"/auth"' "true"
echo -e ""
echo -e ""
echo -e "- add plugin rate-limiting in auth-service"
curl  -s  -sS -X POST \
--url ${kong}/services/auth-service/plugins/ \
--data "name=rate-limiting" \
--data "config.minute=5" \
--data "config.hour=40" \
--data "config.policy=local"

createEndpoint "auth-revoke" "http://auth:5000"  '"/auth/revoke"' "false"
# no auth: this is actually the endpoint used to get a token
# rate plugin limit to avoid brute-force atacks
echo -e ""
echo -e ""
echo -e "- add plugin request-termination in auth-revoke"
curl  -s  -sS -X POST \
--url ${kong}/services/auth-revoke/plugins/ \
    --data "name=request-termination" \
    --data "config.status_code=403" \
    --data "config.message=Not authorized"

createEndpoint "user-service" "http://auth:5000/user"  '"/auth/user"' "true"
addAuthEndpoint "user-service"

createEndpoint "flows" "http://flowbroker:80"  '"/flows"' "true"
addAuthEndpoint "flows"

createEndpoint "flowsIcons" "http://flowbroker:80/icons"  '"/flows/icons"' "true"
addAuthEndpoint "flowsIcons"

createEndpoint "flowsRedImages" "http://flowbroker:80/red/images"  '"/flows/red/images"' "true"
addAuthEndpoint "flowsRedImages"

createEndpoint "history" "http://history:8000"  '"/history"' "true"
addAuthEndpoint "history"

createEndpoint "ejbca-paths" "http://ejbca:5583/"  '"/sign", "/ca", "/user"' "false"
addAuthEndpoint "ejbca-paths"

createEndpoint "data-manager" "http://data-manager:3000/"  '"/export", "/import"' "false"
addAuthEndpoint "data-manager"

createEndpoint "backstage_graphql" "http://backstage:3005/"  '"/graphql(.*)"' "false"

createEndpoint "cron" "http://cron:5000/"  '"/cron"' "false"
addAuthEndpoint "cron"

