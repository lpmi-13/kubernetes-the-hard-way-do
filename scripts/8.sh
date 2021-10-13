# this runs a local script on the remote controllers to bootstrap the control plane
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(doctl compute droplet list ${instance} \
    --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  ssh -i kubernetes.ed25519 \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip < ./scripts/bootstrap_control_plane.sh
done

echo "waiting 30 seconds for etcd to be fully initialized..."
sleep 30

for instance in controller-0; do
  external_ip=$(doctl compute droplet list ${instance} \
    --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  ssh -i kubernetes.ed25519 \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip "kubectl get componentstatus"
done

echo "setting up RBAC from controller-0"

external_ip=$(doctl compute droplet list controller-0 \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

ssh -i kubernetes.ed25519 \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$external_ip < ./scripts/set_up_rbac.sh

KUBERNETES_PUBLIC_ADDRESS=$(doctl compute load-balancer list --output json | jq -r '.[].ip')

curl -k --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version

