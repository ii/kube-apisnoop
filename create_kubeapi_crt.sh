#!/bin/bash

CSR_NAME=k8s-mitm-2.ii

mkdir -p fakecerts
cd fakecerts
echo Generating key
openssl genrsa -out mitm.key 2048
echo Generating k8s-ca.pem
kubectl config view --minify --flatten=true \
    | grep certificate-authority-data | awk -F\  '{print $2}' \
    | base64 -d > k8s-ca.pem
#openssl x509 -text -noout -in ./k8s-ca.pem
echo Generating csr request
#cat k8s-ca.pem | openssl x509 -x509toreq -signkey mitm.key -out k8s.csr
openssl req -new -key mitm.key -out mitm.csr -config ../csr.settings

echo Adding CSR to Kubernetes
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CSR_NAME
spec:
  groups:
  - system:authenticated
  request: $(cat mitm.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

echo Approving CSR
kubectl certificate approve $CSR_NAME
echo Getting result cert
sleep 3
kubectl get csr $CSR_NAME -o jsonpath='{.status.certificate}' | base64 -d > mitm.crt
cat mitm.crt mitm.key > mitm-combined.pem
cp mitm-combined.pem ../charts/tproxy/config/mitm-kube-apiserver.pem
echo Done. Heres the result
openssl x509  -noout -text -in ./mitm.crt
