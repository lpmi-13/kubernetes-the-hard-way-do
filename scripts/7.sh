# this runs a local script on each of the remote controller hosts
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(doctl compute droplet list ${instance} \
    --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  ssh -i kubernetes.ed25519 \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip < ./scripts/bootstrap_etcd_on_controllers.sh
done
