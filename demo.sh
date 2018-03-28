#!/bin/bash
clear
sleep 1
echo "==================================================================="
echo "= kube-appsnoop demo                                              ="
echo "= by Rohan Fletcher                                               ="
echo "= based on work from https://github.com/danisla/kubernetes-tproxy ="
echo "==================================================================="
sleep 1
echo
echo "Description: Transparent proxy that observes the Kubernetes API server requests of pods and addons."
echo
echo "TL;DR: These are the commands that are run"
echo "-------------------------------------------------------------------"
echo -e "\e[32m# Get the code\e[39m"
echo -e "\e[93mgit clone https://github.com/ii/kube-apisnoop.git kube-apisnoop\e[39m"
echo -e "\e[93mcd kube-apisnoop/\e[39m"
echo -e "\e[32m# Create a cert sign request wi0th apiserver DNS and IPs, send to Kubernetes CA to sign\e[39m"
echo -e "\e[93m./create-kubeapi-crt.sh\e[39m"
echo -e "\e[93mls ./fakecerts/\e[39m"
echo -e "\e[32m# Setup a mitmproxy-based pod per node to intercept traffic\e[39m"
echo -e "\e[93m./setup-mitm-proxy.sh\e[39m"
echo -e "\e[32m# Next deploy an example app that makes apiserver requests using kubectl\e[39m"
echo -e "\e[93mkubectl apply -f examples/kubectl-app.yaml\e[39m"
echo -e "\e[32m# Figure out which node's mitmproxy pod needs to be port forwarded so that intercepted requests can be seen.\e[39m"
echo -e "\e[93m./list-pod-nodes.sh\e[39m"
echo -e "\e[93mAPP_NODE=\$(./list-pod-nodes.sh | grep \"^kubectl-app\" | awk '{print \$2}')\e[39m"
echo -e "\e[93mAPP_POD=\$(./list-pod-nodes.sh | grep \"^kubectl-app\" | awk '{print \$1}')\e[39m"
echo -e "\e[93mTPROXY_POD=\$(./list-pod-nodes.sh | grep \"^tproxy-.\+\$APP_NODE\" | awk '{print \$1}')\e[39m"
echo -e "\e[32m# Port forward the tproxy pod so we can access it locally\e[39m"
echo -e "\e[93mkubectl port-forward \$TPROXY_POD 9000:8081 | grep -v \"^Handling\" &\e[39m"
echo -e "\e[93msleep 3\e[39m"
echo -e "\e[32m# Open the web interface to mitmproxy in the default browser\e[39m"
echo -e "\e[93mx-www-browser http://127.0.0.1:9000 2>/dev/null 1>/dev/null\e[39m"
echo -e "\e[32m# Apply the annotation to the example pod so that the traffic is intercepted\e[39m"
echo -e "\e[93msleep 1\e[39m"
echo -e "\e[93mkubectl annotate pod \$APP_POD  initializer.kubernetes.io/tproxy=true\e[39m"
echo -e "\e[93mkubectl logs \$APP_POD  -f --tail=4\e[39m"

sleep 1

echo -e "\e[32m---\e[39m"
read -p "Press enter to step through each of these parts individually..."
echo -e "\e[32m---\e[39m"

echo -e "\e[32m---\e[39m"
read -p "First we create a CSR to masquerade as the apiserver, then import the CSR into Kubernetes and sign it."
echo -e "\e[32m---\e[39m"
echo -e "\e[93m./create-kubeapi-crt.sh\e[39m"
sleep 1
./create-kubeapi-crt.sh
echo -e "\e[32m---\e[39m"
read -p "Next we install our tproxy pods and initializers."
echo -e "\e[32m---\e[39m"
echo -e "\e[93m./setup-mitm-proxy.sh\e[39m"
sleep 1
./setup-mitm-proxy.sh
sleep 2
kubectl get pods
echo -e "\e[32m---\e[39m"
read -p "Now kube-appsnoop has now been setup. All we need is some pods with the right annotations"
echo -e "\e[32m---\e[39m"
read -p "Lets deploy an example app that runs \"kubectl get pods\" every 5 seconds."
echo -e "\e[32m---\e[39m"
echo -e "\e[93mkubectl apply -f examples/kubectl-app.yaml\e[39m"
sleep 1
kubectl apply -f examples/kubectl-app.yaml
sleep 1
kubectl get pods
echo -e "\e[32m---\e[39m"
read -p "To see the traffic logs, we need to find out which tproxy instance is on the same node as our example app."
echo -e "\e[32m---\e[39m"

echo "Here are the names of all the pods in the default namespace:"
echo -e "\e[93m./list-pod-nodes.sh\e[39m"
sleep 1
./list-pod-nodes.sh
APP_NODE=$(./list-pod-nodes.sh | grep "^kubectl-app" | awk '{print $2}')
APP_POD=$(./list-pod-nodes.sh | grep "^kubectl-app" | awk '{print $1}')
TPROXY_POD=$(./list-pod-nodes.sh | grep "^tproxy-.\+$APP_NODE" | awk '{print $1}')
echo "The relevant tproxy pod is $TPROXY_POD"
# set tproxy pod to $TPROXY_POD
echo -e "\e[32m---\e[39m"
read -p "Next we will setup port forwarding to get to the mitmproxy web interface."
echo -e "\e[32m---\e[39m"
echo -e "\e[93mkubectl port-forward $TPROXY_POD 9000:8081 &\e[39m"
sleep 1
kubectl port-forward $TPROXY_POD 9000:8081 | grep -v "^Handling" &
sleep 3
google-chrome http://127.0.0.1:9000 2>/dev/null 1>/dev/null
echo -e "\e[32m---\e[39m"
read -p "We can see there are no API requests being intercepted. The final step is to annotate the pod."
echo -e "\e[32m---\e[39m"
echo -e "\e[93mkubectl annotate pod $APP_POD initializer.kubernetes.io/tproxy=true \e[39m"
sleep 1
kubectl annotate pod $APP_POD  initializer.kubernetes.io/tproxy=true
kubectl logs $APP_POD  -f --tail=4
