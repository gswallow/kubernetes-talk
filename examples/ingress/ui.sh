#!/bin/bash

cat > traefik-ui.yaml <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-ui
  namespace: kube-system
  annotations:
    external-dns.alpha.kubernetes.io/hostname: traefik-ui.k8s.$public_domain.
spec:
  type: LoadBalancer
  selector:
    k8s-app: traefik-ingress-lb
  ports:
  - name: web
    port: 80
    targetPort: 8081
EOF

kubectl create -f traefik-ui.yaml
