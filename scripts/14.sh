for droplet_id in $(doctl compute droplet list --format ID --no-header --tag-name kubernetes); do
  echo "deleting droplet: ${droplet_id}"
  doctl compute droplet delete ${droplet_id} -f
done

# this is an array, since you might have more than one key created while testing
SSH_KEY_IDS=($(doctl compute ssh-key list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-key") | .id'))
if [ -z ${SSH_KEY_IDS} ]; then
  echo "no ssh key found"
else
  for key in $SSH_KEY_IDS; do
    echo "deleting key with ID: ${key}"
    doctl compute ssh-key delete ${key} -f
  done
fi

LOCAL_PRIVATE_SSH_KEY=kubernetes.id_rsa
if [ -f "$LOCAL_PRIVATE_SSH_KEY" ]; then
  echo "deleting local private ssh key previously generated"
  rm -rf kubernetes.id_rsa
else
  echo "no local private key found"
fi

LOCAL_PUBLIC_SSH_KEY=kubernetes.id_rsa.pub
if [ -f "$LOCAL_PUBLIC_SSH_KEY" ]; then
  echo "deleting local public ssh key previously generated"
  rm -rf kubernetes.id_rsa.pub
else
  echo "no local public key found"
fi

LOAD_BALANCER_ID=$(doctl compute load-balancer list --output json \
  | jq -cr '.[] | select(.name == "kubernetes-lb") | .id')
if [ -z ${LOAD_BALANCER_ID} ]; then
  echo "no load balancer found"
else
  echo "deleting load balancer: ${LOAD_BALANCER_ID}"
  doctl compute load-balancer delete ${LOAD_BALANCER_ID} -f
fi

# sometimes it takes the load balancer a few seconds to disappear from the VPC, and the VPC can't be deleted while the load balancer is still registered
sleep 10

FIREWALL_ID=$(doctl compute firewall list --output json | jq -cr '.[] | select(.name == "kubernetes-firewall") | .id')
if [ -z ${FIREWALL_ID} ]; then
  echo "no firewall found"
else
  echo "deleting firewall: ${FIREWALL_ID}"
  doctl compute firewall delete ${FIREWALL_ID} -f
fi

VPC_ID=$(doctl vpcs list --output json \
  | jq -cr '.[] | select(.name == "kubernetes") | .id')
if [ -z ${VPC_ID} ]; then
  echo "no VPC found"
else
  echo "sleeping for 10 seconds to allow droplets to be deleted first"
  sleep 10
  echo "deleting VPC: ${VPC_ID}"
  doctl vpcs delete ${VPC_ID} -f
fi

echo "cleaning up local *.{csr,json,kubeconfig,pem,yaml} files"
rm -rf ./*.{csr,json,kubeconfig,pem,yaml}
