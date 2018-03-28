rm -R fakecerts/
kubectl delete -f examples/kubectl-app.yaml
helm delete --purge tproxy
pkill -f 'kubectl port-forward .+ 9000:8081' 
