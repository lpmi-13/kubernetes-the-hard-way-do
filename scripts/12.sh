kubectl create -f https://raw.githubusercontent.com/lpmi-13/kubernetes-the-hard-way-do/main/deployments/core-dns.yaml

kubectl get pods -l k8s-app=kube-dns -n kube-system

kubectl run busybox --image=busybox:1.28.4 --restart=Never -- sleep 3600

kubectl get pod busybox

kubectl exec -it busybox -- nslookup kubernetes

