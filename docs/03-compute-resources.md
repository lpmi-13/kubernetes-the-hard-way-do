# Provisioning Compute Resources

[Guide](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md)

## Networking

### VPC

```sh
VPC_ID=$(doctl vpcs create \
  --description kubernetes-the-hard-way \
  --ip-range 10.0.0.0/16 \
  --name kubernetes \
  --region ${DO_REGION}
  --output json | jq -r '.[].id')
```

> subnets as a network abstraction don't exist in Digital Ocean. Still trying to work out whether all the droplets are private by default (which you would assume would be more obvious)...it looks like all droplets get a public and private IP address, though presumably the firewalls control whether they are actually publicly accessible

### Kubernetes Public Access - Create a Network Load Balancer

```sh
LOAD_BALANCER_ID=$(doctl compute load-balancer create \
  --name kubernetes-lb \
  --region ${DO_REGION} \
  --forwarding-rules entry_protocol:https,entry_port:443,target_protocol:https,target_port:6443,certificate_id:,tls_passthrough:true \
  --health-check protocol:https,port:6443,path:/healthz,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 \
  --vpc-uuid ${VPC_ID} \
  --output json | jq -r '.[].id')
```

> the load balancer takes about a minute or so to be created, so if the ip address doesn't resolve with the following command, try again a bit later.

```sh
KUBERNETES_PUBLIC_ADDRESS=$(doctl compute load-balancer list \
  --output json | jq -r '.[].ip')
```

## Compute Instances

### SSH Key

```
ssh-keygen -t rsa -b 4096 -f kubernetes.id_rsa
```

then import it via the doctl CLI

```sh
SSH_KEY_FINGERPRINT=$(doctl compute ssh-key import kubernetes-key \
  --public-key-file kubernetes.id_rsa.pub --output json | jq -r '.[].fingerprint')
```

### Kubernetes Controllers

Using `s-1vcpu-1gb` instances, slightly smaller than the t3.micro instances used in the AWS version, but should get the job done

```sh
for i in 0 1 2; do
  doctl compute droplet create controller-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,controller \
    --vpc-uuid ${VPC_ID}
done
```

### Kubernetes Workers

```sh
for i in 0 1 2; do
  doctl compute droplet create worker-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,worker \
    --vpc-uuid ${VPC_ID}
done
```

### Add the Controller nodes to the load balancer

```sh
for i in 0 1 2; do
  droplet_id=$(doctl compute droplet list controller-${i} \
    --output json | jq -r '.[].id')
  doctl compute load-balancer add-droplets ${LOAD_BALANCER_ID} \
    --droplet-ids ${droplet_id}
  echo added dropletId: ${droplet_id}
done
```


### Security Groups (aka Firewall Rules) ...we have to wait til after creating droplets before we can create any ingress/egress rules

```sh
doctl compute firewall create \
  --inbound-rules "protocol:icmp,address:0.0.0.0/0 \
  protocol:tcp,ports:22,address:0.0.0.0/0 \
  protocol:tcp,ports:6443,address:0.0.0.0/0 \
  protocol:tcp,ports:443,address:0.0.0.0/0 \
  protocol:tcp,ports:all,address:10.0.0.0/16 \
  protocol:udp,ports:all,address:10.0.0.0/16" \
  --outbound-rules "protocol:icmp,address:0.0.0.0/0 \
  protocol:tcp,ports:all,address:0.0.0.0/0 \
  protocol:udp,ports:all,address:0.0.0.0/0" \
  --name kubernetes-firewall \
  --tag-names kubernetes
```

Next: [Certificate Authority](04-certificate-authority.md)
