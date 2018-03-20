#!/bin/bash

INSTALL_NAME=tproxy
ACCOUNT_NAME="${INSTALL_NAME}-mitm"
ACCOUNT_SECRET_NAME="${ACCOUNT_NAME}-secret"

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
helm install -n $INSTALL_NAME --set tproxy.useInitializer=true --set tproxy.accountName="$ACCOUNT_NAME" --set tproxy.accountSecretName="$ACCOUNT_SECRET_NAME" .
cd -

# Wait a second
sleep 1

# One liner to get the secrets, patch the CA, then apply changes
kubectl get secrets/$ACCOUNT_SECRET_NAME -o yaml | sed "s/ca.crt:.\+/ca.crt: $MITMPROXY_CERT/" | kubectl apply -f -

kubectl logs -l app=tproxy -c tproxy-podwatch &
