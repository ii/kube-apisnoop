# Prerequisites:
# - An active kubernetes cluster with alpha features and legacy authentication enabled
# git clone https://github.com/ii/kube-apisnoop.git kube-apisnoop
# cd kube-apisnoop/
# Make sure Helm is installed
helm init --wait
# Create a cert sign request with apiserver DNS and IPs, send to Kubernetes CA to sign
./create-kubeapi-crt.sh
# Setup a mitmproxy-based pod per node to intercept traffic
./setup-mitm-proxy.sh
# Next deploy an example app that makes apiserver requests using kubectl
kubectl apply -f examples/kubectl-app.yaml
# Figure out which node's mitmproxy pod needs to be port forwarded so that intercepted requests can be seen.
./list-pod-nodes.sh
export APP_NODE=$(./list-pod-nodes.sh | grep "^kubectl-app" | awk '{print $2}')
export APP_POD=$(./list-pod-nodes.sh | grep "^kubectl-app" | awk '{print $1}')
export TPROXY_POD=$(./list-pod-nodes.sh | grep "^tproxy-.\+$APP_NODE" | awk '{print $1}')
# Port forward the tproxy pod so we can access it locally
kubectl port-forward $TPROXY_POD 9000:8081 | grep -v "^Handling" &
sleep 3
# Open the web interface to mitmproxy in the default browser
[[ $OSTYPE == linux* ]] && xdg-open http://127.0.0.1:9000
[[ $OSTYPE == darwin* ]] && open http://127.0.0.1:9000
# Apply the annotation to the example pod so that the traffic is intercepted
sleep 1
kubectl annotate pod $APP_POD  initializer.kubernetes.io/tproxy=true
kubectl logs $APP_POD  -f --tail=4
