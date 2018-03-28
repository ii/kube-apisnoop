#!/bin/bash

# Generate a serial to prevent duplicates
SERIAL=`date '+%Y%m%d.%H%M%S'`
# Name of our certificate request
CSR_NAME="k8s-mitm-${SERIAL}.ii"

mkdir -p fakecerts
cd fakecerts

# Other way of doing things - download the certificate from the apiserver
# then copy the subject CN and subject alternative names to the csr config
# Note: this will only pick up the first address of the first subset of the first item
# echo -n | openssl s_client -connect $(kubectl get endpoints -o jsonpath='{.items[0].subsets[0].addresses[0].ip}:{.items[0].subsets[0].ports[0].port}') 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > endpoint.crt
# Note: this only gets the first x509v3 subject alternative name line
#SUBJECT_NAMES="`openssl x509 -in endpoint.crt -noout -text 2>&1 | grep -m 1 "X509v3 Subject Alternative Name" -A 1 | tail -n 1 | awk '{$1=$1};1' | awk -F ", " '{for (i=1;i<=NF;i++) print $i}'`"

echo Generating key
openssl genrsa -out mitm.key 2048
# echo Generating k8s-ca.pem
# kubectl config view --minify --flatten=true \
#     | grep certificate-authority-data | awk -F\  '{print $2}' \
#     | base64 -d > k8s-ca.pem
# openssl x509 -text -noout -in ./k8s-ca.pem
# openssl req -x509toreq -in endpoint.crt -signkey mitm.key -out mitm.csr
# openssl x509 -x509toreq doesn't seem to pick up the Subject Alternative Names
# so we template the config and inject the k8s apiserver IPs
echo Generating CSR request
cat ../csr.settings.template |\
        sed "s/REPLACE_INTERNAL_IP/$(kubectl get services -o jsonpath='{.items[0].spec.clusterIP}')/g" |\
        sed "s/REPLACE_EXTERNAL_IP/$(kubectl get endpoints -o jsonpath='{.items[0].subsets[0].addresses[0].ip}')/g" > csr.settings
openssl req -new -key mitm.key -out mitm.csr -config csr.settings

echo Adding CSR to Kubernetes
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CSR_NAME
spec:
  groups:
  - system:authenticated
  request: $(cat mitm.csr | base64 -w0 )
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

echo Approving CSR
kubectl certificate approve $CSR_NAME
echo Getting result cert
# sleep 3
kubectl get csr $CSR_NAME -o jsonpath='{.status.certificate}' | base64 -d > mitm.crt
# Combine the private key and certificate into one file for mitmproxy 
cat mitm.crt mitm.key > mitm-combined.pem
cp mitm-combined.pem ../charts/tproxy/config/mitm-kube-apiserver.pem
echo Done. Heres the result
openssl x509  -noout -text -in ./mitm.crt
