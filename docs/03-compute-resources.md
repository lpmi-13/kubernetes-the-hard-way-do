# Provisioning Compute Resources

[Guide](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md)

## Networking

### VPC

```sh
VPC_ID=$(doctl vpcs create \
  --description kubernetes-the-hard-way \
  --ip-range 10.0.0.0/24 \
  --name kubernetes \
  --region ${D0_REGION}
  --output json | jq -r '.[].id')
```

> subnets as a network abstraction don't exist in Digital Ocean. Still trying to work out whether all the droplets are private by default (which you would assume would be more obvious)...it looks like all droplets get a public and private IP address, though presumably the firewalls control whether they are actually publicly accessible

### Internet Gateway (this also might not exist in DO, but still investigating)

```sh
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 create-tags --resources ${INTERNET_GATEWAY_ID} --tags Key=Name,Value=kubernetes
aws ec2 attach-internet-gateway --internet-gateway-id ${INTERNET_GATEWAY_ID} --vpc-id ${VPC_ID}
```

### Kubernetes Public Access - Create a Network Load Balancer

```sh
LOAD_BALANCER_ID=$(doctl compute load-balancer create \
  --name kubernetes \
  --region ${DO_REGION} \
  --forwarding-rules entry_protocol:tcp,entry_port:443,target_protocol:tcp,target_port:6443 \
  --vpc-uuid ${VPC_ID} \
  --output json | jq -r '.[].id')
```

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
SSH_KEY_FINGERPRINT=$(doctl compute ssh-key import kubernetes \
  --public-key-file kubernetes.id_rsa.pub | jq -r '.[0].fingerprint')
```

### Kubernetes Controllers

Using `s-1vcpu-1gb` instances, slightly smaller than the t3.micro instances used in the AWS version, but should get the job done

```sh
for i in 0 1 2; do
  doctl compute droplet create controller-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --enable-private-networking \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,controller \
    --vpc-uuid ${VPC_ID} \
done
```

> might not actually need any block storage...I guess we'll find out...
```sh
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t3.micro \
    --private-ip-address 10.0.1.1${i} \
    --user-data "name=controller-${i}" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings='{"DeviceName": "/dev/sda1", "Ebs": { "VolumeSize": 50 }, "NoDevice": "" }' \
    --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=controller-${i}"
  echo "controller-${i} created "
done
```

### Kubernetes Workers

```sh
for i in 0 1 2; do
  doctl compute droplet create worker-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --enable-private-networking \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,worker \
    --vpc-uuid ${VPC_ID} \
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


### Security Groups (aka Firewall Rules) ...we need droplets before we can create any ingress/egress rules

```sh
doctl compute firewall create \
  --inbound-rules protocol:tcp,ports:22,address:0.0.0.0/0 \
  --inbound-rules protocol:tcp,ports:6443,address:0.0.0.0/0 \
  --inbound-rules protocol:tcp,ports:443,address:0.0.0.0/0 \
  --inbound-rules protocol:icmp,ports:1,address:0.0.0.0/0 \
  --name kubernetes \
  --tag-names kubernetes
```

Next: [Certificate Authority](04-certificate-authority.md)
