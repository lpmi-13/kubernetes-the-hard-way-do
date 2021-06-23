kubectl create -f https://raw.githubusercontent.com/lpmi-13/kubernetes-the-hard-way-do/main/deployments/core-dns.yaml

sleep 5

kubectl get pods -l k8s-app=kube-dns -n kube-system

sleep 5

kubectl run busybox --image=busybox:1.28.4 --restart=Never -- sleep 3600

sleep 5

kubectl get pod busybox

sleep 5

kubectl exec -it busybox -- nslookup kubernetes

