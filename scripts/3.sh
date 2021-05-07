VPC_ID=$(doctl vpcs create \
  --description kubernetes-the-hard-way \
  --ip-range 10.0.0.0/16 \
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
