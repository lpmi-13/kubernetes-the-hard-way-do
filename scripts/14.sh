for droplet_id in $(doctl compute droplet list --format ID --no-header --tag-name kubernetes); do
  doctl compute droplet delete ${droplet_id} -f
done

SSH_KEY_ID=$(doctl compute ssh-key list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-key") | .id')
if [ -z ${SSH_KEY_ID} ]; then
  echo "no ssh key found";
else
  doctl compute ssh-key delete ${SSH_KEY_ID} -f;
fi

LOAD_BALANCER_ID=$(doctl compute load-balancer list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-lb") | .id')
if [ -z ${LOAD_BALANCER_ID} ]; then
  echo "no load balancer found";
else
  doctl compute load-balancer delete $LOAD_BALANCER_ID -f;
fi

FIREWALL_ID=$(doctl compute firewall list --output json \
  | jq -cr '.[] | select(.name == "kuberenetes-firewall") | .id')
if [ -z ${FIREWALL_ID} ]; then
  echo "no firewall found";
else
  doctl compute firewall delete ${FIREWALL_ID} -f;
fi

VPC_ID=$(doctl vpcs list --output json \
  | jq -cr '.[] | select(.name == "kubernetes") | .id')
if [ -z ${VPC_ID} ]; then
  echo "no VPC found";
else
  doctl vpcs delete ${VPC_ID} -f;
fi
