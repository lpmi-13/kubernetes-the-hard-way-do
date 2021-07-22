source scripts/set_env.sh

VPC_ID=$(doctl vpcs create \
  --description kubernetes-the-hard-way \
  --ip-range 10.240.0.0/24 \
  --name kubernetes \
  --region ${DO_REGION} \
  --output json | jq -r '.[].id')

echo "VPC_ID is $VPC_ID"

LOAD_BALANCER_ID=$(doctl compute load-balancer create \
  --name kubernetes-lb \
  --region ${DO_REGION} \
  --forwarding-rules entry_protocol:https,entry_port:443,target_protocol:https,target_port:6443,certificate_id:,tls_passthrough:true \
  --health-check protocol:https,port:6443,path:/healthz,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 \
  --vpc-uuid ${VPC_ID} \
  --output json | jq -r '.[].id')

echo "LOAD_BALANCER_ID is $LOAD_BALANCER_ID"

LOAD_BALANCER_IP=$(doctl compute load-balancer list --output json | jq -r '.[].ip')

# the load balancer usually takes about a minute or so to start
while [ "$LOAD_BALANCER_IP" = "null" ];
do
    echo "waiting for load balancer to start"
    sleep 10
    LOAD_BALANCER_IP=$(doctl compute load-balancer list --output json | jq -r '.[].ip')
done

echo "Load balancer finished set up!"

KUBERNETES_PUBLIC_ADDRESS=$(doctl compute load-balancer list \
  --output json | jq -r '.[].ip')

echo "KUBERNETES_PUBLIC_ADDRESS is $KUBERNETES_PUBLIC_ADDRESS"

ssh-keygen -t rsa -b 4096 -f kubernetes.id_rsa -N ""

SSH_KEY_FINGERPRINT=$(doctl compute ssh-key import kubernetes-key \
  --public-key-file kubernetes.id_rsa.pub --output json | jq -r '.[].fingerprint')

for i in 0 1 2; do
  doctl compute droplet create controller-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,controller \
    --vpc-uuid ${VPC_ID}
done

for i in 0 1 2; do
  doctl compute droplet create worker-${i} \
    --image ubuntu-18-04-x64 \
    --size s-1vcpu-1gb \
    --region ${DO_REGION} \
    --ssh-keys ${SSH_KEY_FINGERPRINT} \
    --tag-names kubernetes,worker \
    --vpc-uuid ${VPC_ID}
done

for i in 0 1 2; do
  droplet_id=$(doctl compute droplet list controller-${i} \
    --output json | jq -r '.[].id')
  doctl compute load-balancer add-droplets ${LOAD_BALANCER_ID} \
    --droplet-ids ${droplet_id}
  echo added dropletId: ${droplet_id}
done

doctl compute firewall create \
  --inbound-rules "protocol:icmp,address:0.0.0.0/0 \
protocol:tcp,ports:22,address:0.0.0.0/0 \
protocol:tcp,ports:6443,address:0.0.0.0/0 \
protocol:tcp,ports:443,address:0.0.0.0/0 \
protocol:tcp,ports:all,address:10.240.0.0/24 \
protocol:udp,ports:all,address:10.240.0.0/24 \
protocol:tcp,ports:all,address:10.200.0.0/16 \
protocol:udp,ports:all,address:10.200.0.0/16" \
  --outbound-rules "protocol:icmp,address:0.0.0.0/0 \
protocol:tcp,ports:all,address:0.0.0.0/0 \
protocol:udp,ports:all,address:0.0.0.0/0" \
  --name kubernetes-firewall \
  --tag-names kubernetes
