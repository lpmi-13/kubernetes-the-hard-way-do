# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network routes. 

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

Essentially, we want a pod in each worker node to be able to find a pod in another worker node. So in case of a pod on worker-0 communicating with a pod on worker-1, the route is something like the following:

- pod on worker-0 has a CIDR range of 10.200.0.0/24 (from the kubelet config on that node). It needs to know that for contacting a pod in CIDR range 10.200.1.0/24 (a different subnet), it can use the worker-1 node as a gateway.
- we want to add a route like the following:

```sh
$ ip route add 10.200.1.0/24 via 10.240.0.7
```
(10.200.1.0/24 is the possible range for a pod on worker-1, and 10.240.0.7 is the internal IP address for worker-1)

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table and routes on the workers

Print the internal IP address and Pod CIDR range for each worker instance and create route table entries:

run the following commands in each of the worker nodes:

- worker-0

```sh
ip route add 10.200.1.0/24 via 10.240.0.7
ip route add 10.200.2.0/24 via 10.240.0.8
```

- worker-1

```sh
ip route add 10.200.0.0/24 via 10.240.0.6
ip route add 10.200.2.0/24 via 10.240.0.8
```

- worker-2

```sh
ip route add 10.200.0.0/24 via 10.240.0.6
ip route add 10.200.1.0/24 via 10.240.0.7
```

## DNS resolution on the controllers

We also need the controllers to be able to resolve the DNS for `worker-0` to its IP address (`10.240.0.6`). So we need to run the following on each controller:

```
cat <<EOF | sudo tee -a /etc/hosts
10.240.0.6 worker-0
10.240.0.7 worker-1
10.240.0.8 worker-2
EOF
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
