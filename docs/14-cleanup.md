# Cleaning Up

In this lab you will delete the compute resources created during this tutorial.

## Compute Instances

Delete the controller and worker compute instances:

```
for droplet_id in $(doctl compute droplet list --format ID --no-header --tag-name kubernetes); do
  doctl compute droplet delete ${droplet_id} -f
done

```

Delete the stored SSH key:
```
SSH_KEY_ID=$(doctl compute ssh-key list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-key") | .id')
doctl compute ssh-key delete ${SSH_KEY_ID} -f
```

## Networking

Delete the external load balancer:

```
LOAD_BALANCER_ID=$(doctl compute load-balancer list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-lb") | .id')
doctl compute load-balancer delete $LOAD_BALANCER_ID -f

```

Delete the firewall:

```
FIREWALL_ID=$(doctl compute firewall list --output json \
  | jq -cr '.[] | select(.name == "kuberenetes-firewall") | .id')
doctl compute firewall delete ${FIREWALL_ID} -f
```

Delete the VPC:

```
VPC_ID=$(doctl vpcs list --output json \
  | jq -cr '.[] | select(.name == "kubernetes") | .id')
doctl vpcs delete ${VPC_ID} -f

```
