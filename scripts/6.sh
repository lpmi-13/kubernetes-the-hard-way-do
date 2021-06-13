ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(doctl compute droplet list ${instance} \
    --output json | jq -cr '.[].networks.v4 | .[] | select(.type == "public") | .ip_address')

  scp -i kubernetes.id_rsa \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    encryption-config.yaml root@${external_ip}:~/
done

