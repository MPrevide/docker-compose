#!/bin/sh -ex

kong="http://apigw:8001"


authAPI() {
    echo "authConfigService ${1}"

    curl -o /dev/null -s  -i -X POST \
    --url ${kong}/services/${1}/plugins/ \
    --data "name=pepkong" \
    --data "config.pdpUrl=http://auth:5000/pdp"

    curl -o /dev/null -s  -i -X POST \
    --url ${kong}/services/${1}/plugins/ \
    --data "name=jwt"
}

createService() {
#$1 = Service Name
#$2 = URL (ex.: http://gui:80)
    echo "createService ${1} ${2}"
    curl -o /dev/null -s -i -X PUT \
    --url ${kong}/services/${1} \
    --data "name=${1}" \
    --data "url=${2}"
}

createRoute() {
#$1 = Service Name
#$2 = Route Name
#$3 = PATHS (ex.: /,/x)
#$4 = strip_path
(curl -o /dev/null ${kong}/services/${1}/routes/${2} -sS -X PUT \
    --header "Content-Type: application/json" \
    -d @- ) <<PAYLOAD
{
    "paths": ["${3}"],
    "strip_path": ${4}
}
PAYLOAD
}



createAPI(){
#$1 = Service Name
#$2 = URL (ex.: http://gui:80)
#$3 = PATHS (ex.: /,/x)
#$4 = strip_path
    createService "${1}" "${2}"
    createRoute "${1}" "${1}_route" "${3}" "${4}"
}


createAPI "gui" "http://gui:80"  "/" "false"

createAPI  "data-broker" "http://data-broker:80"  '/device/(.*)/latest", "/subscription' "false"
authAPI "data-broker"

createAPI "data-streams" "http://data-broker:80"  "/stream" "true"
authAPI "data-streams"

createAPI "ws-http" "http://data-broker:80"  "/socket.io" "false"

createAPI "device-manager" "http://device-manager:5000"  '"/device", "/template"' "false"
authAPI "device-manager"

createAPI "image" "http://image-manager:5000"  '/fw-image' "true"
authAPI "image"

createAPI "auth-permissions-service" "http://auth:5000/pap"  '/auth/pap' "true"
authAPI "auth-permissions-service"

createAPI "auth-service" "http://auth:5000"  '/auth' "true"
# authAPI "auth-service"


# no auth: this is actually the endpoint used to get a token
# rate plugin limit to avoid brute-force atacks
# curl -o /dev/null -sS -X POST ${kong}/apis/auth-service/plugins \
#     --data "name=rate-limiting" \
#     --data "config.minute=5" \
#     --data "config.hour=40" \
#     --data "config.policy=local"

createAPI "auth-revoke" "http://auth:5000"  '/auth/revoke' "false"
authAPI "auth-revoke"

# curl -o /dev/null -sS -X POST  ${kong}/apis/auth-revoke/plugins \
#     --data "name=request-termination" \
#     --data "config.status_code=403" \
#     --data "config.message=Not authorized"

createAPI "user-service" "http://auth:5000/user"  '/auth/user' "true"
authAPI "user-service"

createAPI "flows" "http://flowbroker:80"  '/flows' "true"
authAPI "flows"

createAPI "flowsIcons" "http://flowbroker:80/icons"  '/flows/icons' "true"
authAPI "flowsIcons"

createAPI "flowsRedImages" "http://flowbroker:80/red/images"  '/flows/red/images' "true"
authAPI "flowsRedImages"

createAPI "history" "http://history:8000"  '/history' "true"
authAPI "history"

createAPI "ejbca-paths" "http://ejbca:5583/"  '"/sign", "/ca", "/user"' "false"
authAPI "ejbca-paths"

createAPI "data-manager" "http://data-manager:3000/"  '"/export", "/import"' "false"
authAPI "data-manager"

createAPI "backstage_graphql" "http://backstage:3005/"  '/graphql(.*)' "false"

createAPI "cron" "http://cron:5000/"  '/cron' "false"
authAPI "cron"

