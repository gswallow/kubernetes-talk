#!/bin/bash

cat > 2048.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: "play2048-ingress"
  labels:
    app: "play2048"
  annotations:
    kubernetes.io/ingress.class: nginx
    external-dns.alpha.kubernetes.io/hostname: play2048.k8s.$public_domain.
spec:
  rules:
  - host: play2048.k8s.$public_domain
    http:
      paths:
      - path: /
        backend:
          serviceName: "play2048-service"
          servicePort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: "play2048-service"
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: "play2048"
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: "play2048-deployment"
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: "play2048"
    spec:
      containers:
      - image: alexwhen/docker-2048
        imagePullPolicy: Always
        name: "play2048"
        ports:
        - containerPort: 80
EOF

kubectl create -f 2048.yaml
