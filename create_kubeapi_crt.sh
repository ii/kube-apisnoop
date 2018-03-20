#!/bin/bash

CSR_NAME=tproxy-kubernetes3.ii

mkdir -p fakecerts
cd fakecerts
echo Generating key
openssl genrsa -out server.key 2048
echo Generating csr request
openssl req -new -key server.key -out server.csr -config ../csr.settings


echo Adding CSR to Kubernetes
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CSR_NAME
spec:
  groups:
  - system:authenticated
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

echo Approving CSR
kubectl certificate approve $CSR_NAME
echo Getting result cert
sleep 3
kubectl get csr $CSR_NAME -o jsonpath='{.status.certificate}' | base64 -d > server.crt
echo Done. Heres the result
openssl x509  -noout -text -in ./server.crt
