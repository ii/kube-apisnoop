#!/bin/bash

INSTALL_NAME=tproxy

cd charts/tproxy

# if certificates havent been created yet, create them
if [ ! -d "$(pwd)/certs" ]; then
    echo "Certs not found, creating certs"
    docker run --rm -v ${PWD}/certs/:/home/mitmproxy/.mitmproxy mitmproxy/mitmproxy >/dev/null 2>&1
fi
# load the fake CA cert for injection into the mitm service account
MITMPROXY_CERT=$(cat ./certs/mitmproxy-ca-cert.pem | base64 -w 0)


# Run the install with useInitializer=true
echo "Installing tproxy using helm...."
helm install -n $INSTALL_NAME --set tproxy.useInitializer=true .
cd -

# Wait a second
sleep 1
