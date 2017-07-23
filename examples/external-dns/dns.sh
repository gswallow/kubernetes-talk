#!/bin/bash
cat > external-dns-deployment.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: kube-system
  name: external-dns
spec:
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      containers:
      - name: external-dns
        image: registry.opensource.zalan.do/teapot/external-dns:v0.3.0
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=k8s.$public_domain. # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
        - --provider=aws
        - --registry=txt
        - --txt-owner-id=`uuidgen`
        - --debug
        - --policy=sync # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
EOF

kubectl create -f external-dns-deployment.yaml
