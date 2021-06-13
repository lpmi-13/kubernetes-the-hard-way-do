for instance in worker-0 worker-1 worker-2; do
  external_ip=$(doctl compute droplet list ${instance} \
    --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  ssh -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip < ./scripts/bootstrap_workers.sh
done

echo "waiting 30 seconds before checking worker status"
sleep 30

external_ip=$(doctl compute droplet list controller-0 \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$external_ip "kubectl get nodes --kubeconfig admin.kubeconfig"

