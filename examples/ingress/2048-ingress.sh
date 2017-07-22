#!/bin/bash

cat | tee 2048-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: "ingress-2048"
  annotations:
  labels:
    app: ingress-2048
  annotations:
    whatever-class: traefik
spec:
  rules:
  - host: 2048.k8s.$public_domain.
    http:
      paths:
      - path: /
        backend:
          serviceName: "service-2048"
          servicePort: 80
EOF

#kubectl create -f 2048-ingress.yaml
