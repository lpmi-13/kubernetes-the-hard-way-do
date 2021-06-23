# now we do some manual route table updating, cuz digital ocean doesn't have a nice networking API

worker_0_external_ip=$(doctl compute droplet list worker-0 \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") \
.ip_address')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$worker_0_external_ip -C 'ip route add 10.200.1.0/24 via 10.240.0.7;ip route add 10.200.2.0/24 via 10.240.0.8'

worker_1_external_ip=$(doctl compute droplet list worker-1 \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") \
.ip_address')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$worker_1_external_ip -C 'ip route add 10.200.0.0/24 via 10.240.0.6;ip route add 10.200.2.0/24 via 10.240.0.8'

worker_2_external_ip=$(doctl compute droplet list worker-2 \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") \
.ip_address')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$worker_2_external_ip -C 'ip route add 10.200.0.0/24 via 10.240.0.6;ip route add 10.200.1.0/24 via 10.240.0.7'

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(doctl compute droplet list ${instance} \
  --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  ssh -i kubernetes.id_rsa root@$external_ip < ./scripts/update_dns.sh
done
