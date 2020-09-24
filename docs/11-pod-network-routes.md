# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network routes. 

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

Essentially, we want a pod in each worker node to be able to find a pod in another worker node. So in case of a pod on worker-0 communicating with a pod on worker-1, the route is something like the following:

- pod on worker-0 has a CIDR range of 10.200.0.0/24 (from the kubelet config on that node). It needs to know that for contacting a pod in CIDR range 10.200.1.0/24 (a different subnet), it can use the worker-1 node as a gateway.
- we want to add a route like the following:

```sh
$ route add -net 10.200.1.0/24 gw 10.0.0.7
```
(10.200.1.0/24 is the possible range for a pod on worker-1, and 10.0.0.7 is the internal IP address for worker-1)

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table and routes

Print the internal IP address and Pod CIDR range for each worker instance and create route table entries:

run the following commands in each of the worker nodes:

- worker-0

```sh
route add -net 10.200.1.0/24 gw 10.0.0.7
route add -net 10.200.2.0/24 gw 10.0.0.8
```

- worker-1

```sh
route add -net 10.200.0.0/24 gw 10.0.0.6
route add -net 10.200.2.0/24 gw 10.0.0.8
```

- worker-2

```sh
route add -net 10.200.0.0/24 gw 10.0.0.6
route add -net 10.200.1.0/24 gw 10.0.0.7
```

**STILL TRYING TO FIGURE THIS OUT, SO THIS IS AS FAR AS WE GO WITH THE EDITS TO THIS PAGE ...its very possible that this works and we don't need the rest of the page...but also possible that it doesn't work at all**

---

> output

```
10.0.1.20 10.200.0.0/24
{
    "Return": true
}
10.0.1.21 10.200.1.0/24
{
    "Return": true
}
10.0.1.22 10.200.2.0/24
{
    "Return": true
}
```

## Validate Routes

Validate network routes for each worker instance:

```sh
aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --query 'RouteTables[].Routes'
```

> output

```
[
    [
        {
            "DestinationCidrBlock": "10.200.0.0/24",
            "InstanceId": "i-0879fa49c49be1a3e",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0612e82f1247c6282",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.200.1.0/24",
            "InstanceId": "i-0db245a70483daa43",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0db39a19f4f3970f8",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.200.2.0/24",
            "InstanceId": "i-0b93625175de8ee43",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0cc95f34f747734d3",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.0.0.0/16",
            "GatewayId": "local",
            "Origin": "CreateRouteTable",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "0.0.0.0/0",
            "GatewayId": "igw-00d618a99e45fa508",
            "Origin": "CreateRoute",
            "State": "active"
        }
    ]
]
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
