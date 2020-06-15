#!/bin/bash

# First command is adding the sync directive to the keyavl zone
# Second command is adding the zone_sync listener and directive that lets NGINX sync the state of the keyval zone. It uses service discovery to find the other NGINX instances based off of a headless service in kubernetes for the nginx-ingress pods.
# Third command creates the headless service with port 12345
# Fourth and Fifth apply the service and the nginx-config that includes the stream config for zone_sync and the keyval zones.
sed -i.orig 's/\(.*keyval_zone.*\);/\1 sync;/g' nginx-config.yaml
sed -i 's/\(^data:.*\)/\1 \n  stream-snippets:\n    resolver kube-dns.kube-system.svc.cluster.local valid=5s;\n\n    server {\n      listen 0.0.0.0:12345;\n      zone_sync;\n      zone_sync_server nginx-ingress-headless.nginx-ingress.svc.cluster.local:12345 resolve;\n    }\n/g' nginx-config.yaml
cat << EOF >> headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-headless
  namespace: nginx-ingress
spec:
  clusterIP: None
  ports:
  - port: 12345
    targetPort: 12345
    protocol: TCP
    name: zonesync
  selector:
    app: nginx-ingress
EOF
kubectl apply -f headless.yaml
kubectl apply -f nginx-config.yaml
